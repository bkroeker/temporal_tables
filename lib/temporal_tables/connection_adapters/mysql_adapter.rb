module TemporalTables
	module ConnectionAdapters
		# TODO: Test if this copied code actually works.
		module MysqlAdapter
			def self.included(base)
				base.class_eval do
					def create_temporal_triggers(table_name)
						column_names = columns(table_name).map(&:name)

						execute %{
							create trigger #{table_name}_ai after insert on #{table_name} 
							for each row
							begin
								set @current_time = now();

								insert into #{temporal_name(table_name)} (#{column_names.join(', ')}, eff_from)
								values (#{column_names.collect {|c| "new.#{c}"}.join(', ')}, @current_time);

							end
						}
						
						execute %{
							create trigger #{table_name}_au after update on #{table_name} 
							for each row
							begin
								set @current_time = now();

								update #{temporal_name(table_name)} set eff_to = @current_time
								where id = new.id
								and eff_to = '9999-12-31';

								insert into #{temporal_name(table_name)} (#{column_names.join(', ')}, eff_from)
								values (#{column_names.collect {|c| "new.#{c}"}.join(', ')}, @current_time);

							end
						}
						
						execute %{
							create trigger #{table_name}_ad after delete on #{table_name} 
							for each row
							begin
								set @current_time = now();

								update #{temporal_name(table_name)} set eff_to = @current_time
								where #{base_id_name} = old.id
								and eff_to = '9999-12-31';

							end
						}
					end
				end
			end
		end
	end
end
