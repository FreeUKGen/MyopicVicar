# Temporary diagnostic controller: used to manually verify 500 error rendering
# and Errbit/Airbrake reporting. Remove once verified.
class DiagnosticsController < ApplicationController
  def trigger_500
    raise 'Manually triggered test error (diagnostics#trigger_500) to verify 500/Errbit handling'
  end
end
