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
end
