# frozen_string_literal: true

module TemporalTables
  module ConnectionAdapters
    module PostgreSQLAdapter
      def drop_temporal_triggers(table_name)
        execute "drop trigger #{table_name}_ai on #{table_name}"
        execute "drop trigger #{table_name}_au on #{table_name}"
        execute "drop trigger #{table_name}_ad on #{table_name}"
      end

      def create_temporal_triggers(table_name, primary_key) # rubocop:disable Metrics/MethodLength
        column_names = columns(table_name).map(&:name)

        execute %{
          create or replace function #{table_name}_ai() returns trigger as $#{table_name}_ai$
            declare
              cur_time timestamp without time zone;
            begin
              cur_time := localtimestamp;

              insert into #{temporal_name(table_name)} (#{column_list(column_names)}, eff_from)
              values (#{column_names.collect { |c| "new.#{c}" }.join(', ')}, cur_time);

              return null;
            end
          $#{table_name}_ai$ language plpgsql;

          drop trigger if exists #{table_name}_ai on #{table_name};
          create trigger #{table_name}_ai after insert on #{table_name}
          for each row execute procedure #{table_name}_ai();
        }

        execute %{
          create or replace function #{table_name}_au() returns trigger as $#{table_name}_au$
            declare
              cur_time timestamp without time zone;
            begin
              cur_time := localtimestamp;

              update #{temporal_name(table_name)} set eff_to = cur_time
              where #{primary_key} = new.#{primary_key}
                and eff_to = '#{TemporalTables::END_OF_TIME}';

              insert into #{temporal_name(table_name)} (#{column_list(column_names)}, eff_from)
              values (#{column_names.collect { |c| "new.#{c}" }.join(', ')}, cur_time);

              return null;
            end
          $#{table_name}_au$ language plpgsql;

          drop trigger if exists #{table_name}_au on #{table_name};
          create trigger #{table_name}_au after update on #{table_name}
          for each row execute procedure #{table_name}_au();
        }

        execute %{
          create or replace function #{table_name}_ad() returns trigger as $#{table_name}_ad$
            declare
              cur_time timestamp without time zone;
            begin
              cur_time := localtimestamp;

              update #{temporal_name(table_name)} set eff_to = cur_time
              where #{primary_key} = old.#{primary_key}
                and eff_to = '#{TemporalTables::END_OF_TIME}';

              return null;
            end
          $#{table_name}_ad$ language plpgsql;

          drop trigger if exists #{table_name}_ad on #{table_name};
          create trigger #{table_name}_ad after delete on #{table_name}
          for each row execute procedure #{table_name}_ad();
        }
      end

      def column_list(column_names)
        column_names.map { |c| "\"#{c}\"" }.join(', ')
      end
    end
  end
end
