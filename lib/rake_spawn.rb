# Fire-and-forget launcher for background rake tasks started from web requests.
#
# Why this exists: `spawn("rake ...")` / `spawn("bundle exec rake ...")` runs the
# child through a shell using the environment the web server (Passenger) hands
# down. On rails2 that environment still has an old Ruby ahead of the current one
# on PATH, so the child booted the wrong Ruby and died with Bundler::GemNotFound
# before the task ran - silently, because nothing captured its output.
#
# This helper avoids the shell entirely: it execs the *running* interpreter
# (RbConfig.ruby) against the bundler-aware bin/rake binstub, passes the task and
# its arguments as separate argv entries (no quoting games), and appends the
# child's stdout+stderr to log/rake_spawn.log so failures are visible.
#
#   RakeSpawn.run('build:freereg_new_update[create_search_records,waiting,no,a-9]')
#   RakeSpawn.run("foo:process_embargo_records[#{id},#{email}]")
module RakeSpawn
  LOGFILE = Rails.root.join('log', 'rake_spawn.log').freeze

  # task_and_args: usually a single "task[arg1,arg2]" string (rake parses the
  # brackets itself). Extra elements are passed straight through as argv, e.g.
  # RakeSpawn.run('some:task', '--trace').
  def self.run(*task_and_args)
    pid = Process.spawn(
      RbConfig.ruby,
      Rails.root.join('bin', 'rake').to_s,
      *task_and_args.map(&:to_s),
      chdir: Rails.root.to_s,
      out: [LOGFILE.to_s, 'a'],
      err: [LOGFILE.to_s, 'a']
    )
    Process.detach(pid)
    Rails.logger.warn("RAKE_SPAWN: pid=#{pid} #{task_and_args.inspect}")
    pid
  end
end
