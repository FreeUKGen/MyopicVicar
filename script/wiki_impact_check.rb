#!/usr/bin/env ruby
# frozen_string_literal: true

# Wiki impact checker, run by .github/workflows/wiki_impact_check.yml on every PR.
#
# Looks at what a PR changes and suggests which GitHub wiki pages might need an
# update, and what to add there. It is advisory only: it never fails the build
# and never edits the wiki - the developer decides whether anything is worth
# documenting.
#
# How it works (plain text matching, no Rails boot, stdlib only):
#   1. `git diff base...head` for the files we care about (models, controllers,
#      constraints, mailers, lib, routes, Gemfile, config).
#   2. Pulls out doc-worthy changes from the added/removed lines: Mongoid fields,
#      associations, validations, callbacks, scopes, constants, public methods,
#      routes.
#   3. Maps each changed file to wiki pages that mention its path (e.g. the
#      "**Models:** `app/models/syndicate.rb`" header line) or its class name.
#   4. Flags things the PR removed/renamed that the wiki still mentions.
#   5. For files the wiki doesn't cover yet, suggests which domain section they
#      belong in (DOMAIN_RULES below - keep it in step with _Sidebar.md).
#
# Usage: ruby script/wiki_impact_check.rb BASE_SHA HEAD_SHA WIKI_DIR [OUTPUT_FILE]
# Writes a markdown report to OUTPUT_FILE (default: stdout). Writes nothing if
# the PR touches no relevant files.

require 'open3'

BASE_SHA, HEAD_SHA, WIKI_DIR, OUTPUT_FILE = ARGV
abort 'usage: wiki_impact_check.rb BASE_SHA HEAD_SHA WIKI_DIR [OUTPUT_FILE]' unless BASE_SHA && HEAD_SHA && WIKI_DIR

REPO = ENV.fetch('GITHUB_REPOSITORY', 'FreeUKGen/MyopicVicar')
WIKI_URL = "https://github.com/#{REPO}/wiki"
MARKER = '<!-- wiki-impact-check -->'

WATCHED = %r{\A(app/(models|controllers|constraints|mailers|uploaders)/.*\.rb|lib/.*\.(rb|rake)|config/routes\.rb|config/.*\.yml|Gemfile|\.ruby-version)\z}.freeze

# First matching rule wins. `page` is the existing wiki page to suggest; when a
# section has no page yet, `page` is nil and `section` names the planned one.
DOMAIN_RULES = [
  [/freecen|vld_|piece|dwelling|search_record_freecen/, nil, 'FreeCEN (census)'],
  [/transreg/, nil, 'Legacy transreg migration'],
  [/contact|feedback|message|donat|reminder_to_donate|nimbus/, 'Communication-and-Engagement', 'Communication & Engagement'],
  [/assignment|csvfile|syndicate|manage_|userid|image_server|favorite_action|s3bucket|batch/, 'Transcriber-and-Coordinator-Workflow', 'Transcriber & Coordinator Workflow'],
  [/search|saved_search|legacy_search/, nil, 'Search & discovery'],
  [/emendation|place_edit_reason|tna_change_log/, nil, 'Data quality / corrections'],
  [/register|church|place|toponym|county|countr|source|gap|embargo|freereg|physical_file|attic_file|asset/, nil, 'FreeREG core records'],
  [/page|site_statistic|software_version/, nil, 'CMS / site & system']
].freeze

def git(*args)
  out, status = Open3.capture2('git', *args)
  status.success? ? out : ''
end

def camelize(name)
  name.split('_').map(&:capitalize).join
end

def page_link(page)
  "[#{page.tr('-', ' ')}](#{WIKI_URL}/#{page})"
end

# ---------------------------------------------------------------- wiki index

WIKI_PAGES = Dir.glob(File.join(WIKI_DIR, '*.md')).each_with_object({}) do |path, pages|
  name = File.basename(path, '.md')
  next if name.start_with?('_') # _Sidebar, _Footer

  pages[name] = File.readlines(path, chomp: true)
end

def pages_mentioning(regex)
  WIKI_PAGES.each_with_object({}) do |(page, lines), hits|
    line_nos = lines.each_index.select { |i| lines[i].match?(regex) }.map { |i| i + 1 }
    hits[page] = line_nos unless line_nos.empty?
  end
end

# Pages that document a file: by path first (strong), then by class name in
# code formatting, e.g. `Syndicate`, `Syndicate#foo`, `Syndicate.bar` (weaker).
def pages_for_file(path)
  by_path = pages_mentioning(/#{Regexp.escape(path)}/)
  return [by_path, :path] unless by_path.empty?

  klass = camelize(File.basename(path, '.rb'))
  [pages_mentioning(/`#{klass}([`#.]|::)/), :class]
end

def domain_for(path)
  base = File.basename(path, '.rb')
  rule = DOMAIN_RULES.find { |re, _, _| base.match?(re) }
  rule ? { page: rule[1], section: rule[2] } : nil
end

# ---------------------------------------------------------------- diff parsing

# Returns [[status, path, old_path]]; old_path only set for renames.
def changed_files
  git('diff', '--name-status', '-M', "#{BASE_SHA}...#{HEAD_SHA}").lines.map do |line|
    status, a, b = line.chomp.split("\t")
    path = b || a
    next unless path.match?(WATCHED) || a.match?(WATCHED)

    [status[0], path, (b ? a : nil)]
  end.compact
end

def diff_lines(path)
  added = []
  removed = []
  git('diff', '-U0', "#{BASE_SHA}...#{HEAD_SHA}", '--', path).each_line do |l|
    next if l.start_with?('+++', '---')

    added << l[1..].chomp if l.start_with?('+')
    removed << l[1..].chomp if l.start_with?('-')
  end
  [added, removed]
end

# Methods defined after a bare `private`/`protected` line are treated as
# non-public. Crude, but right for the way this codebase is written.
def private_methods_in(path, sha)
  src = git('show', "#{sha}:#{path}")
  seen_private = false
  src.each_line.with_object([]) do |l, names|
    seen_private = true if l.match?(/^\s*(private|protected)\s*$/)
    names << Regexp.last_match(1) if seen_private && l =~ /^\s*def\s+([a-z_][\w?!]*)/
  end
end

PATTERNS = {
  field: /^\s*field\s+:(\w+)/,
  association: /^\s*(?:has_many|has_one|belongs_to|embeds_many|embeds_one|embedded_in|has_and_belongs_to_many)\s+:(\w+)/,
  validation: /^\s*(validates?\w*\s+.*)/,
  callback: /^\s*((?:before|after|around)_\w+\s+.*)/,
  scope: /^\s*scope\s+:(\w+)/,
  constant: /^\s*([A-Z][A-Z0-9_]+)\s*=/,
  class_method: /^\s*def\s+self\.([a-z_][\w?!]*)/,
  method: /^\s*def\s+([a-z_][\w?!]*)/,
  index: /^\s*index\s*\(?\s*(\{.*?\})/
}.freeze

LABELS = {
  field: 'field', association: 'association', validation: 'validation', callback: 'callback',
  scope: 'scope', constant: 'constant', class_method: 'class method', method: 'method', index: 'index'
}.freeze

def extract(lines)
  lines.each_with_object(Hash.new { |h, k| h[k] = [] }) do |line, found|
    PATTERNS.each do |kind, re|
      next unless (m = line.match(re))

      found[kind] << m[1].strip
      break # first match only, so `def self.x` isn't also counted as `def x`
    end
  end
end

# ---------------------------------------------------------------- routes

def route_controller(line)
  return Regexp.last_match(1) if line =~ /to:\s*['"](\w+)#/ || line =~ /=>\s*['"](\w+)#/
  return Regexp.last_match(1) if line =~ /controller:\s*['"]?:?(\w+)/
  return Regexp.last_match(1) if line =~ /^\s*resources?\s+:(\w+)/
  return Regexp.last_match(1) if line =~ /^\s*(?:get|post|put|patch|delete|match)\s+['"]\/?(\w+)/

  nil
end

# ---------------------------------------------------------------- analysis

page_notes = Hash.new { |h, k| h[k] = [] } # page => [markdown bullets]
stale = []         # [page, line_no, reason]
undocumented = []  # [path, domain]

files = changed_files
exit 0 if files.empty?

files.each do |status, path, old_path|
  case path
  when 'config/routes.rb'
    added, removed = diff_lines(path)
    { 'Added' => added, 'Removed' => removed }.each do |verb, lines|
      lines.each do |l|
        next if l.strip.empty? || l.strip.start_with?('#')
        next unless (ctrl = route_controller(l))

        ctrl_path = "app/controllers/#{ctrl}_controller.rb"
        pages, = pages_for_file(ctrl_path)
        bullet = "#{verb} route: `#{l.strip}` — update the **Routes:** line"
        if pages.empty?
          undocumented << [ctrl_path, domain_for(ctrl_path)] unless undocumented.any? { |p, _| p == ctrl_path }
        else
          pages.each_key { |pg| page_notes[pg] << bullet }
        end
        next unless verb == 'Removed' && (route_path = l[%r{['"](/?[\w/:]+)['"]}, 1])

        pages_mentioning(/#{Regexp.escape(route_path.delete_prefix('/'))}/).each do |pg, nos|
          nos.each { |n| stale << [pg, n, "route `#{route_path}` was removed"] }
        end
      end
    end
    next
  when 'Gemfile', '.ruby-version', %r{\Aconfig/.*\.yml\z}
    added, removed = diff_lines(path)
    next if added.empty? && removed.empty?

    target = WIKI_PAGES.key?('Development-Setup') ? 'Development-Setup' : 'Architecture'
    page_notes[target] << "`#{path}` changed — check setup steps, versions and required config still match"
    if path == 'Gemfile' && WIKI_PAGES.key?('Architecture')
      gems = (added + removed).map { |l| l[/^\s*gem\s+['"]([\w-]+)/, 1] }.compact.uniq
      page_notes['Architecture'] << "Gems changed: #{gems.map { |g| "`#{g}`" }.join(', ')} — update the stack overview if any are significant" unless gems.empty?
    end
    next
  end

  klass = camelize(File.basename(path, '.rb'))

  if status == 'D'
    pages, = pages_for_file(path)
    pages.each { |pg, nos| nos.each { |n| stale << [pg, n, "`#{path}` (#{klass}) was deleted"] } }
    next
  end

  if status == 'R' && old_path
    pages_mentioning(/#{Regexp.escape(old_path)}/).each do |pg, nos|
      nos.each { |n| stale << [pg, n, "`#{old_path}` was renamed to `#{path}`"] }
    end
  end

  added, removed = diff_lines(path)
  plus = extract(added)
  minus = extract(removed)
  hidden = private_methods_in(path, HEAD_SHA)
  was_hidden = status == 'A' ? [] : private_methods_in(old_path || path, BASE_SHA)
  pages, match_type = pages_for_file(path)

  bullets = []
  PATTERNS.each_key do |kind|
    new_items = plus[kind] - minus[kind]
    gone_items = minus[kind] - plus[kind]
    if kind == :method
      new_items -= hidden
      gone_items -= was_hidden
    end

    fmt = lambda do |x|
      case kind
      when :method then "`#{klass}##{x}`"
      when :class_method then "`#{klass}.#{x}`"
      else "`#{x}`"
      end
    end
    new_items.uniq.each { |x| bullets << "New #{LABELS[kind]}: #{fmt.call(x)}" }
    gone_items.uniq.each do |x|
      bullets << "Removed #{LABELS[kind]}: #{fmt.call(x)}"
      name = x[/\A\w+[?!]?/]
      next unless name && name.length > 3 && %i[field association scope class_method method constant].include?(kind)

      pages.each_key do |pg|
        WIKI_PAGES[pg].each_with_index do |text, i|
          stale << [pg, i + 1, "mentions `#{name}`, removed from `#{path}`"] if text.match?(/`[^`]*\b#{Regexp.escape(name)}\b[^`]*`/)
        end
      end
    end
  end

  if status == 'A'
    bullets.unshift("New file `#{path}` (`#{klass}`) — add it to the page header and describe what it does")
  end

  if pages.empty?
    undocumented << [path, domain_for(path)] if status == 'A' || !bullets.empty?
    next
  end
  next if bullets.empty? && status != 'A'

  pages.each_key do |pg|
    note = match_type == :class ? " _(matched on class name `#{klass}`, may be a passing mention)_" : ''
    page_notes[pg] << "**`#{path}`**#{note}"
    bullets.each { |b| page_notes[pg] << "  - #{b}" }
    page_notes[pg] << '  - Logic changed (no structural change detected) — check the behaviour described still holds' if bullets.empty?
  end
end

# ---------------------------------------------------------------- report

exit 0 if page_notes.empty? && stale.empty? && undocumented.empty?

out = +"#{MARKER}\n## 📚 Wiki impact check\n\n"
out << "This PR touches code that is (or could be) covered in the [project wiki](#{WIKI_URL}). "
out << "These are **suggestions only** — nothing is blocked. Update the wiki if you think it's worth it, or ignore.\n\n"

unless stale.empty?
  out << "### ⚠️ Possibly out of date\n\nThe wiki mentions things this PR removed or renamed:\n\n"
  stale.uniq.group_by(&:first).each do |pg, rows|
    out << "- #{page_link(pg)}\n"
    rows.first(10).each { |_, n, why| out << "  - line #{n}: #{why}\n" }
    out << "  - …and #{rows.size - 10} more\n" if rows.size > 10
  end
  out << "\n"
end

unless page_notes.empty?
  out << "### ✏️ Pages that may need an update\n\n"
  page_notes.each do |pg, notes|
    out << "- [ ] #{page_link(pg)}\n"
    notes.uniq.each { |n| out << "  #{n.start_with?('  ') ? n : "- #{n}"}\n" }
  end
  out << "\n"
end

unless undocumented.empty?
  out << "### 🆕 Not covered by the wiki yet\n\n"
  out << "| File | Suggested place |\n|---|---|\n"
  undocumented.each do |path, dom|
    where = if dom.nil?
              'No obvious section — maybe [Architecture](' + WIKI_URL + '/Architecture) or a new page'
            elsif dom[:page] && WIKI_PAGES.key?(dom[:page])
              "#{page_link(dom[:page])} (new sub-page, or a section on the overview)"
            else
              "_#{dom[:section]}_ (planned section, no page yet)"
            end
    out << "| `#{path}` | #{where} |\n"
  end
  out << "\nNo need to document everything in this PR — only if the change is significant.\n\n"
end

out << "<sub>Generated by `script/wiki_impact_check.rb` from the diff against `#{BASE_SHA[0, 7]}`. " \
       "Heuristic text matching — may miss things or over-report.</sub>\n"
out = out[0, 60_000] + "\n\n_(truncated)_\n" if out.size > 60_000

OUTPUT_FILE ? File.write(OUTPUT_FILE, out) : puts(out)
