module TemporalTables
	module ConnectionAdapters
		module PostgreSQLAdapter
			def self.included(base)
				base.class_eval do
					def create_temporal_triggers(table_name)
						column_names = columns(table_name).map(&:name)

						execute %{
							create or replace function #{table_name}_ai() returns trigger as $#{table_name}_ai$
								declare
									cur_time timestamp without time zone;
								begin
									cur_time := localtimestamp;

									insert into #{temporal_name(table_name)} (#{column_names.join(', ')}, eff_from)
									values (#{column_names.collect {|c| "new.#{c}"}.join(', ')}, cur_time);
									
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
									where id = new.id
										and eff_to = '9999-12-31';
								
									insert into #{temporal_name(table_name)} (#{column_names.join(', ')}, eff_from)
									values (#{column_names.collect {|c| "new.#{c}"}.join(', ')}, cur_time);

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
									where id = old.id
										and eff_to = '9999-12-31';

									return null;
								end
							$#{table_name}_ad$ language plpgsql;

							drop trigger if exists #{table_name}_ad on #{table_name};
							create trigger #{table_name}_ad after delete on #{table_name} 
							for each row execute procedure #{table_name}_ad();
						}
					end
				end
			end
		end
	end
end
