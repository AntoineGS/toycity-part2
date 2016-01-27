require 'json'
require 'date'

def print_data(section,out) #6th level
  if section == "product"
    $products_data.each do |p|
      out.() << "Title: #{p[:product_title]}\n"
    	out.() << "	Retail Price        : $#{p[:retail_price]}\n"
    	out.() << "	Number of Purchases : #{p[:number_purch]} units\n"
    	out.() << "	Total Sales         : $#{p[:total_sales]}\n"
    	out.() << "	Average Sales Price : $#{p[:avg_sales_price]}\n"
    	out.() << "	Average Discount    : $#{p[:avg_discount]}\n"
    	out.() << "\n"
    end
  elsif section == "brand"
    $brands_data.each do |b|
      out.() << "Name: #{b[:brandname]}\n"
      out.() << "	Total stock        : #{b[:stock]} units\n"
	    out.() << "	Average sell price : $#{b[:avg_price]}\n"
	    out.() << "	Total Sales        : $#{b[:total_sales]}\n"
	    out.() << "\n"
    end
  end
end

def print_heading(section,out,params = {}) #5th level
  if section == "header"
    #ASCII art taken from http://patorjk.com/software/taag/#p=display&f=Ivrit&t=SALES%20REPORT%0A
    out.() << " ____    _    _     _____ ____    ____  _____ ____   ___  ____ _____\n"
    out.() << "/ ___|  / \\  | |   | ____/ ___|  |  _ \\| ____|  _ \\ / _ \\|  _ \\_   _|\n"
    out.() << "\\___ \\ / _ \\ | |   |  _| \\___ \\  | |_) |  _| | |_) | | | | |_) || |\n"
    out.() << " ___) / ___ \\| |___| |___ ___) | |  _ <| |___|  __/\| |_| |  _ < | |\n"
    out.() << "|____/_/   \\_\\_____|_____|____/  |_| \\_\\_____|_|    \\___/|_| \\_\\|_|\n"

  elsif section == "product"
    out.() << "                     _            _       \n"
    out.() << "                    | |          | |      \n"
    out.() << " _ __  _ __ ___   __| |_   _  ___| |_ ___ \n"
    out.() << "| '_ \\| '__/ _ \\ / _` | | | |/ __| __/ __|\n"
    out.() << "| |_) | | | (_) | (_| | |_| | (__| |_\\__ \\\n"
    out.() << "| .__/|_|  \\___/ \\__,_|\\__,_|\\___|\\__|___/\n"
    out.() << "| |                                       \n"
    out.() << "|_|                                       \n"

  elsif section == "brand"
    out.() << " _                         _     \n"
    out.() << "| |                       | |    \n"
    out.() << "| |__  _ __ __ _ _ __   __| |___ \n"
    out.() << "| '_ \\| '__/ _` | '_ \\ / _` / __|\n"
    out.() << "| |_) | | | (_| | | | | (_| \\__ \\\n"
    out.() << "|_.__/|_|  \\__,_|_| |_|\\__,_|___/\n"
  end

  if params[:date]==true #added for the sake of the exercise
    out.() << "Date of report: #{Date.today}\n"
  end

  out.() << "\n"
end

def build_output_string(indent_num)
  @indent = " " * indent_num #Create an indentation based on the number passed
  lambda { $report_file << @indent }
end

def make_section(section,heading_indent_num = 0,data_indent_num = 0,date = "N") #4th level
  #Generates the output format to reduce code clutter
  print_heading(section,build_output_string(heading_indent_num),date:(is_why?(date)))
  print_data(section,build_output_string(data_indent_num))
end

def is_why?(date) #added for the sake of the exercise
  date == "Y"
end

def print_report #3rd level
  make_section("header",0,0,"Y")
  make_section("product",4,8)
  make_section("brand",4,8)
end

def generate_data #3rd level
  $products_data = [] #will hold all the data for the products report
  $brands_data = [] #will hold all the data for the brands report
  @product_index = 0 #initialize the products index for the hash array to 0

  $products_hash["items"].each do |toy|
    $products_data.push(product_title: toy["title"], number_purch: toy["purchases"].count, retail_price: toy["full-price"],total_sales: 0, avg_sales_price: 0, avg_discount: 0) #Assumption is that products only appear once in the file, this creates a new product for each entry in toy

    #Brands calculations
    @brand_index = $brands_data.find_index{|x| x[:brandname] == toy["brand"]}
    #If it does not exist in the array, the index is null
  	#It is then added to the array
  	if @brand_index.nil?
  		$brands_data.push(brandname: toy["brand"], stock: toy["stock"], avg_price: toy["full-price"], total_sales: 0, toy_count: 1)
  		@brand_index = $brands_data.count - 1
  	else
  		#If it is there, then the stock of the current toy is added to existing total
  		$brands_data[@brand_index][:stock]+= toy["stock"]
  		$brands_data[@brand_index][:avg_price]= ((($brands_data[@brand_index][:avg_price] * $brands_data[@brand_index][:toy_count]).to_f + toy["full-price"].to_f) / ($brands_data[@brand_index][:toy_count] + 1)).round(2)
  		$brands_data[@brand_index][:toy_count]+= 1
  	end

  	toy["purchases"].each do |purch|
      #product calculations
      $products_data[@product_index][:total_sales]+=purch["price"]

      #brand calculations
      #Could not figure out how to use += with .round(2) in this scenario. It seems the 0 from the initialization is not exactly 0
      $brands_data[@brand_index][:total_sales] = ($brands_data[@brand_index][:total_sales] + purch["price"].to_f).round(2)
    end

  	$products_data[@product_index][:avg_sales_price] = $products_data[@product_index][:total_sales] / toy["purchases"].count
    $products_data[@product_index][:avg_discount] = $products_data[@product_index][:retail_price].to_f - $products_data[@product_index][:avg_sales_price].to_f

    @product_index += 1
  end
end

def create_report #2nd level
  generate_data
  print_report
end

def setup_files #2nd level
  path = File.join(File.dirname(__FILE__), '../data/products.json')
  file = File.read(path)
  $products_hash = JSON.parse(file)
  $report_file = File.new("report.txt", "w+")
end

def start #1st level
  setup_files # load, read, parse, and create the files
  create_report # create the report!
end

start # call start method to trigger report generation



# Print "Sales Report" in ascii art

# Print today's date

# Print "Products" in ascii art

# For each product in the data set:
	# Print the name of the toy
	# Print the retail price of the toy
	# Calculate and print the total number of purchases
	# Calculate and print the total amount of sales
	# Calculate and print the average price the toy sold for
	# Calculate and print the average discount (% or $) based off the average sales price

# Print "Brands" in ascii art

# For each brand in the data set:
	# Print the name of the brand
	# Count and print the number of the brand's toys we stock
	# Calculate and print the average price of the brand's toys
	# Calculate and print the total sales volume of all the brand's toys combined
