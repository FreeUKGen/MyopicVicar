Mobvious.configure do |config|
  config.strategies = [ Mobvious::Strategies::MobileESP.new(:mobile_tablet_desktop) ]
end