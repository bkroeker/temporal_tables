# frozen_string_literal: true

def adapter_name
  if Gemika::Env.gem?('pg')
    'postgresql'
  elsif Gemika::Env.gem?('mysql2')
    'mysql'
  else
    raise 'Cannot determine adapter'
  end
end

def table_exists?(name)
  ActiveRecord::Base.connection.table_exists?(name)
end

def function_exists?(name)
  case adapter_name
  when 'postgresql'
    begin
      ActiveRecord::Base.connection.execute("select(pg_get_functiondef('#{name}'::regprocedure))").present?
    rescue ActiveRecord::StatementInvalid
      false
    end
  when 'mysql' then raise NotImplementedError
  else raise "Unknown adapter #{adapter_name}"
  end
end

def trigger_exists?(name) # rubocop:disable Metrics/MethodLength
  case adapter_name
  when 'postgresql'
    ActiveRecord::Base.connection.execute(
      "select (pg_get_triggerdef(oid)) FROM pg_trigger WHERE tgname = '#{name}'"
    ).first.present?
  when 'mysql'
    ActiveRecord::Base.connection.execute(
      'SHOW TRIGGERS FROM temporal_tables_test'
    ).find { |row| row.first == name }.present?
  else
    raise "Unknown adapter #{adapter_name}"
  end
end
