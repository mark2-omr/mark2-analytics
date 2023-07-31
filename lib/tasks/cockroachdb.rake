namespace :cockroachdb do
  task print_import_commands: :environment do
    timestamp = Time.now.strftime('%Y%m%d_%H%M')

    print "% ccloud cluster sql\n\n"
    print "Password: #{Rails.application.credentials.cockroachdb.password}\n\n"
    print "> BACKUP DATABASE #{Rails.application.credentials.cockroachdb.database}\n"
    print "  INTO \'s3://#{Rails.application.credentials.aws.bucket}/mark2_analytics_production_#{timestamp}?AWS_ACCESS_KEY_ID=#{Rails.application.credentials.aws.access_key_id}&AWS_SECRET_ACCESS_KEY=#{Rails.application.credentials.aws.secret_access_key}'\n"
    print "  AS OF SYSTEM TIME '-10s';\n\n"

    print "% cockroach sql --insecure\n\n"
    print "> DROP DATABASE mark2_analytics_development CASCADE;\n\n"
    print "> RESTORE DATABASE #{Rails.application.credentials.cockroachdb.database} FROM LATEST\n"
    print "  IN \'s3://#{Rails.application.credentials.aws.bucket}/mark2_analytics_production_#{timestamp}?AWS_ACCESS_KEY_ID=#{Rails.application.credentials.aws.access_key_id}&AWS_SECRET_ACCESS_KEY=#{Rails.application.credentials.aws.secret_access_key}'\n"
    print "  WITH new_db_name = 'mark2_analytics_development';\n"
  end

  task print_export_commands: :environment do
    timestamp = Time.now.strftime('%Y%m%d_%H%M')

    print "% cockroach sql --insecure\n\n"
    print "> BACKUP DATABASE mark2_analytics_development\n"
    print "  INTO \'s3://#{Rails.application.credentials.aws.bucket}/mark2_analytics_development_#{timestamp}?AWS_ACCESS_KEY_ID=#{Rails.application.credentials.aws.access_key_id}&AWS_SECRET_ACCESS_KEY=#{Rails.application.credentials.aws.secret_access_key}'\n"
    print "  AS OF SYSTEM TIME '-10s';\n\n"

    print "% ccloud cluster sql\n\n"
    print "> RESTORE DATABASE mark2_analytics_development FROM LATEST\n"
    print "  IN \'s3://#{Rails.application.credentials.aws.bucket}/mark2_analytics_development_#{timestamp}?AWS_ACCESS_KEY_ID=#{Rails.application.credentials.aws.access_key_id}&AWS_SECRET_ACCESS_KEY=#{Rails.application.credentials.aws.secret_access_key}'\n"
    print "  WITH new_db_name = '#{Rails.application.credentials.cockroachdb.database}';\n"
  end
end
