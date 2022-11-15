# frozen_string_literal: true

module TemporalTables
  module ConnectionAdapters
    module AbstractMysqlAdapter
      def drop_temporal_triggers(table_name)
        execute "drop trigger #{table_name}_ai"
        execute "drop trigger #{table_name}_au"
        execute "drop trigger #{table_name}_ad"
      end

      def create_temporal_triggers(table_name, primary_key) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        column_names = columns(table_name).map(&:name)

        execute "drop trigger if exists #{table_name}_ai"
        execute %{
          create trigger #{table_name}_ai after insert on #{table_name}
          for each row
          begin
            set @current_time = utc_timestamp(6);

            insert into #{temporal_name(table_name)} (#{column_names.join(', ')}, eff_from)
            values (#{column_names.collect { |c| "new.#{c}" }.join(', ')}, @current_time);

          end
        }

        execute "drop trigger if exists #{table_name}_au"
        execute %{
          create trigger #{table_name}_au after update on #{table_name}
          for each row
          begin
            set @current_time = utc_timestamp(6);

            update #{temporal_name(table_name)} set eff_to = @current_time
            where #{primary_key} = new.#{primary_key}
            and eff_to = '#{TemporalTables::END_OF_TIME}';

            insert into #{temporal_name(table_name)} (#{column_names.join(', ')}, eff_from)
            values (#{column_names.collect { |c| "new.#{c}" }.join(', ')}, @current_time);

          end
        }

        execute "drop trigger if exists #{table_name}_ad"
        execute %{
          create trigger #{table_name}_ad after delete on #{table_name}
          for each row
          begin
            set @current_time = utc_timestamp(6);

            update #{temporal_name(table_name)} set eff_to = @current_time
            where #{primary_key} = old.#{primary_key}
            and eff_to = '#{TemporalTables::END_OF_TIME}';

          end
        }
      end
    end
  end
end
