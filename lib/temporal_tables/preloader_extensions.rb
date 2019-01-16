module TemporalTables
  # Uses the at time when fetching preloaded records
  module PreloaderExtensions
    def build_scope
      # It seems the at time can be in either of these places, but not both,
      # depending on when the preloading happens to be done
      at_time = @owners.first.at_value if @owners.first.respond_to?(:at_value)
      at_time ||= Thread.current[:at_time]

      if at_time
        super.at(at_time)
      else
        super
      end
    end
  end
end

ActiveRecord::Associations::Preloader::Association.prepend TemporalTables::PreloaderExtensions
