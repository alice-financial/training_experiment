require 'faker'
require 'date'
require 'csv'
require 'weighted_randomizer'

@output_file_name = ARGV[0]
@number_of_rows = ARGV[1].to_i || 100

# shapes

@station_names = "1st Street,5th Street5th Street,5th Street,7th Street/Metro Center,17th Street/Santa Monica College,26th Street/Bergamot,103rd Street/Watts Towers,Allen,Anaheim Street,APU/Citrus College,Arcadia,Artesia,Atlantic,Avalon,Aviation/LAX,Azusa Downtown,Chinatown,Civic Center/Grand Park,Compton,Crenshaw,Culver City,Del Amo,Del Mar,Douglas,Downtown Long Beach,Downtown Santa Monica,Duarte/City of Hope,East LA Civic Center,El Segundo,Expo/Bundy,Expo/Crenshaw,Expo/La Brea,Expo/Sepulveda,Expo/Vermont,Expo/Western,Expo Park/USC,Farmdale,Fillmore,Firestone,Florence,Grand/LATTC,Harbor Freeway,Hawthorne/Lennox,Heritage Square,Highland Park,Hollywood/Highland,Hollywood/Vine,Hollywood/Western,Indiana,Irwindale,Jefferson/USC,La Cienega/Jefferson,Lake,Lakewood Boulevard,LATTC/Ortho Institute,Lincoln/Cypress,Little Tokyo/Arts District,Long Beach Boulevard,Maravilla,Mariachi Plaza,Mariposa,Memorial Park,Monrovia,North Hollywood,Norwalk,Pacific Avenue,Pacific Coast Highway,Palms,Pershing Square,Pico,Pico/Aliso,Redondo Beach,San Pedro,Sierra Madre Villa,Slauson,Soto,South Pasadena,Southwest Museum,Union Station,Universal City/Studio City,Vermont/Athens,Vermont/Beverly,Vermont/Santa Monica,Vermont/Sunset,Vernon,Wardlow,Washington,Westlake/MacArthur Park,Westwood/Rancho Park,Willow Street,Willowbrook/Rosa Parks,Wilshire/Normandie,Wilshire/Vermont,Wilshire/Western".split(",")

def mta_nyc_transit_shape
  {
    name: "ITO/NFT Tram",
    amount: [11750,2825,4000,2725,2000].sample
  }
end

def mta_mvm_shape
  {
    name: "ITO DVM*#{@station_names.sample}",
    amount: [11750,2825,4000,2725,2000].sample
  }
end

def checkcard_mta_mvm_shape
  {
    name: "CHECKDISK #{Faker::Number.number(4)} ITO DVM*#{@station_names.sample} NEW FAKE TOWN HW #{Faker::Number.number(23)}",
    amount: [11750,2825,4000,2725,2000].sample
  }
end

def metropolitan_transportation_authority_shape
  {
    name: "Impressive Tram Organization",
    amount: [3100,11650,2000,650,2725,4000,1000,500,600,1600,1525,1905,3000,11200,11750,2005,1995,2825,3200,1500].sample
  }
end

# generator

@shape_sampler = WeightedRandomizer.new({
  mta_nyc_transit_shape: 1,
  mta_mvm_shape: 1.5,
  checkcard_mta_mvm_shape: 1,
  metropolitan_transportation_authority_shape: 5
})

def generate_transit_system_csv(size)
  headers = ["name", "amount", "date", "banking_category_id", "category"]

  rows = size.times.map do
    category_hash = [
      { banking_category_id: "22000000", category: "--- - Travel " },
      { banking_category_id: "NA", category: nil }
    ].sample

    shape = send(@shape_sampler.sample)
      .merge({ date: Faker::Date.between(Date.new(2014,1,1), Date.today).to_s })
      .merge(category_hash)

    [shape[:name], shape[:amount], shape[:date], shape[:banking_category_id], shape[:category]]
  end

  CSV.open(@output_file_name, 'wb+') do |csv|
    csv << headers
    rows.each { |row| csv << row }
  end
end

generate_transit_system_csv(@number_of_rows)
