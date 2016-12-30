require 'dotenv'
require 'google/apis/prediction_v1_6'

Dotenv.load

scopes = ['https://www.googleapis.com/auth/prediction', 'https://www.googleapis.com/auth/devstorage.read_only']
service = ::Google::Apis::PredictionV1_6::PredictionService.new
credentials = ::Google::Auth::ServiceAccountCredentials.make_creds(scope: scopes)
service.authorization = credentials
project = 'alice-ml'
id = 'data-doge-model-1'

response = service.get_trained_model(project, id)

pp response
