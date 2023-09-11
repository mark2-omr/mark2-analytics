namespace :survey do
  task aggregate_all: :environment do
    surveys = Survey.all
    surveys.each do |survey|
      print "Aggregating Survey##{survey.id}\n"
      survey.aggregate_results
    end
  end

  task aggregate: :environment do
    survey = Survey.find(9)
    survey.aggregate_results
    survey.export_results
  end

  task export_all: :environment do
    surveys = Survey.all
    surveys.each do |survey|
      print "Exporting Survey##{survey.id}\n"
      survey.export_results
    end
  end

  task import_active_storage: :environment do
    Survey.all.each do |survey|
      if survey.merged2
        survey.merged.attach(io: StringIO.new(survey.merged2),
          filename: "Mark2_Results_#{survey.id}.xlsx")
      end
    end
  end
end
