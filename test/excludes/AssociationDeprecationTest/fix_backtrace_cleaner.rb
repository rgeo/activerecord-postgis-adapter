module FixBacktraceCleaner
  def setup
    super
    bc = ActiveSupport::BacktraceCleaner.new
    bc.remove_silencers!
    bc.remove_filters!
    bc.add_silencer { !_1.include?(::AssociationDeprecationTest::TestCase::THIS_FILE) }
    ActiveRecord::LogSubscriber.backtrace_cleaner = bc
  end
end
