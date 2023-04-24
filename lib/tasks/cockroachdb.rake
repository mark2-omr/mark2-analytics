namespace :cockroachdb do
  task print_backup_command: :environment do
    print "BACKUP DATABASE <BACKUP_DB_NAME>\n"
    print "  INTO \'s3://#{Rails.application.credentials.aws.bucket}/mark2_analytics_backups?AWS_ACCESS_KEY_ID=#{Rails.application.credentials.aws.access_key_id}&AWS_SECRET_ACCESS_KEY=#{Rails.application.credentials.aws.secret_access_key}'\n"
    print "  AS OF SYSTEM TIME '-10s';\n"
  end

  task print_restore_command: :environment do
    print "RESTORE DATABASE <RESTORE_DB_NAME> FROM LATEST\n"
    print "  IN \'s3://#{Rails.application.credentials.aws.bucket}/mark2_analytics_backups?AWS_ACCESS_KEY_ID=#{Rails.application.credentials.aws.access_key_id}&AWS_SECRET_ACCESS_KEY=#{Rails.application.credentials.aws.secret_access_key}'\n"
    print "  WITH new_db_name = '<NEW_DB_NAME>';\n"
  end
end
