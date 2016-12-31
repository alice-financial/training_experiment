require 'dotenv'
require 'google/apis/prediction_v1_6'
require 'csv'
require 'google_drive'

Dotenv.load

scopes = ['https://www.googleapis.com/auth/prediction', 'https://www.googleapis.com/auth/devstorage.read_only']
credentials = ::Google::Auth::ServiceAccountCredentials.make_creds(scope: scopes)

@service = ::Google::Apis::PredictionV1_6::PredictionService.new
@service.authorization = credentials
@project = 'alice-ml'
@model = 'data-doge-model-7'

# helpers

def train_model_with!(row)
  update_object = Google::Apis::PredictionV1_6::Update.new({
    csv_instance: row,
    output: "mass_transit"
  })
  @service.update_trained_model(@project, @model, update_object)
  puts "added row to model for training: #{row}!"
end

def wait_while_model_updates!
  done_updating = false
  until done_updating do
    puts "model updating ..."
    sleep(60)
    response = @service.get_trained_model(@project, @model)
    done_updating = response.training_status == "DONE"
  end
  puts "model updated!"
end

def prediction_results_for(rows)
  puts "fetching prediction results for our test data ..."
  rows.map do |row|
    sleep(1)
    input = Google::Apis::PredictionV1_6::Input::Input.new({ csv_instance: row })
    input_object = Google::Apis::PredictionV1_6::Input.new({ input: input })
    response = @service.predict_trained_model(@project, @model, input_object)
    {
      mass_transit: response.output_multi[0].score,
      not_eligible: response.output_multi[1].score,
      csv_instance: row
    }
  end
end

def save_prediction_results_to_csv!(prediction_results, filepath)
  puts "saving prediction results to csv!"
  CSV.open(filepath, "wb+") do |csv|
    csv << ["csv_instance", "mass_transit", "not_eligible"]
    prediction_results.each do |result|
      csv << [
        result[:csv_instance],
        result[:mass_transit],
        result[:not_eligible]
      ]
    end
  end
end

def send_averaged_prediction_results_to_google_spreadsheet!(prediction_results, n)
  puts "saving averaged prediction results to google spreadsheet!"
  session = GoogleDrive::Session.from_service_account_key("service_account_config.json")
  spreadsheet = session.spreadsheet_by_key(ENV["SPREADSHEET_KEY"])
  worksheet = spreadsheet.worksheets.first
  worksheet.insert_rows(worksheet.num_rows + 1, [[
    n,
    prediction_results.inject(0) { |sum, result| sum + result[:mass_transit].to_f } / prediction_results.length,
    prediction_results.inject(0) { |sum, result| sum + result[:not_eligible].to_f } / prediction_results.length
  ]])
  worksheet.save
end

# training script

training_rows = CSV.read('./training.csv')[1..-1]
testing_rows = CSV.read('./testing.csv')[1..-1]

training_rows.each_with_index do |training_row, i|
  n = i + 1
  puts "n = #{n}"
  train_model_with!(training_row)
  wait_while_model_updates!
  prediction_results = prediction_results_for(testing_rows)
  save_prediction_results_to_csv!(prediction_results, "./prediction_results/#{n}.csv")
  send_averaged_prediction_results_to_google_spreadsheet!(prediction_results, n)
end
