# frozen_string_literal: true

# General Register Office initialism for FreeBMD: visible "GRO" for sighted users;
# spans carry dots for screen readers. Single source for the HTML fragment.
module GroAbbrev
  ACCESSIBILITY_HTML = 'G<span class="accessibility">.</span>R<span class="accessibility">.</span>O'.freeze
end
