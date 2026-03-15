// =============================================================================
// FILE: lib/core/data/location_data.dart
// PURPOSE: Country → State → City cascading data for address fields
// =============================================================================

/// Location data for cascading Country → State → City selection.
/// Country is first, state updates per country, city updates per state.
class LocationData {
  LocationData._();

  /// All countries with their states. States contain cities.
  static const Map<String, Map<String, List<String>>> data = {
    'India': _indiaStates,
    'United States': _usaStates,
    'United Kingdom': _ukStates,
    'United Arab Emirates': _uaeStates,
    'Pakistan': _pakistanStates,
    'Bangladesh': _bangladeshStates,
    'Sri Lanka': _sriLankaStates,
    'Nepal': _nepalStates,
    'Singapore': _singaporeStates,
    'Malaysia': _malaysiaStates,
  };

  /// Country names sorted for display
  static List<String> get countries => data.keys.toList()..sort();

  /// States for a country
  static List<String> statesFor(String country) {
    final states = data[country]?.keys.toList();
    return states ?? [];
  }

  /// Cities for a state within a country
  static List<String> citiesFor(String country, String state) {
    final cities = data[country]?[state];
    return cities ?? [];
  }

  // ── India: States with major cities ─────────────────────────────────────────
  static const Map<String, List<String>> _indiaStates = {
    'Andhra Pradesh': ['Visakhapatnam', 'Vijayawada', 'Guntur', 'Nellore', 'Kurnool', 'Kakinada', 'Rajahmundry', 'Tirupati', 'Kadapa', 'Anantapur'],
    'Arunachal Pradesh': ['Itanagar', 'Naharlagun', 'Pasighat', 'Namsai', 'Changlang', 'Tezu', 'Ziro', 'Bomdila', 'Tawang'],
    'Assam': ['Guwahati', 'Silchar', 'Dibrugarh', 'Jorhat', 'Nagaon', 'Tinsukia', 'Tezpur', 'Bongaigaon', 'Dhubri', 'Diphu'],
    'Bihar': ['Patna', 'Gaya', 'Bhagalpur', 'Muzaffarpur', 'Darbhanga', 'Purnia', 'Bihar Sharif', 'Arrah', 'Begusarai', 'Katihar'],
    'Chhattisgarh': ['Raipur', 'Bhilai', 'Bilaspur', 'Korba', 'Durg', 'Rajnandgaon', 'Rajgarh', 'Raigarh', 'Jagdalpur', 'Ambikapur'],
    'Goa': ['Panaji', 'Margao', 'Vasco da Gama', 'Mapusa', 'Ponda', 'Bicholim', 'Curchorem', 'Sanquelim', 'Quepem'],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar', 'Jamnagar', 'Junagadh', 'Gandhinagar', 'Anand', 'Nadiad', 'Morbi', 'Bharuch', 'Education City'],
    'Haryana': ['Gurgaon', 'Faridabad', 'Panipat', 'Ambala', 'Yamunanagar', 'Rohtak', 'Hisar', 'Karnal', 'Sonipat', 'Panchkula'],
    'Himachal Pradesh': ['Shimla', 'Dharamshala', 'Solan', 'Mandi', 'Palampur', 'Baddi', 'Nahan', 'Kullu', 'Manali', 'Chamba'],
    'Jharkhand': ['Ranchi', 'Jamshedpur', 'Dhanbad', 'Bokaro', 'Deoghar', 'Hazaribagh', 'Giridih', 'Ramgarh', 'Medininagar', 'Phusro'],
    'Karnataka': ['Bangalore', 'Mysore', 'Hubli', 'Mangalore', 'Belgaum', 'Gulbarga', 'Davanagere', 'Bellary', 'Shimoga', 'Tumkur'],
    'Kerala': ['Thiruvananthapuram', 'Kochi', 'Kozhikode', 'Thrissur', 'Kollam', 'Alappuzha', 'Palakkad', 'Malappuram', 'Kannur', 'Kasaragod'],
    'Madhya Pradesh': ['Bhopal', 'Indore', 'Jabalpur', 'Gwalior', 'Ujjain', 'Sagar', 'Dewas', 'Satna', 'Ratlam', 'Rewa'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Thane', 'Nashik', 'Aurangabad', 'Solapur', 'Kolhapur', 'Amravati', 'Navi Mumbai'],
    'Manipur': ['Imphal', 'Thoubal', 'Bishnupur', 'Churachandpur', 'Kakching', 'Ukhrul', 'Senapati', 'Tamenglong'],
    'Meghalaya': ['Shillong', 'Tura', 'Nongstoin', 'Jowai', 'Nongpoh', 'Williamnagar', 'Resubelpara', 'Mawkyrwat'],
    'Mizoram': ['Aizawl', 'Lunglei', 'Saiha', 'Champhai', 'Kolasib', 'Serchhip', 'Mamit', 'Khawzawl'],
    'Nagaland': ['Kohima', 'Dimapur', 'Mokokchung', 'Tuensang', 'Wokha', 'Zunheboto', 'Phek', 'Mon', 'Longleng', 'Kiphire'],
    'Odisha': ['Bhubaneswar', 'Cuttack', 'Rourkela', 'Berhampur', 'Sambalpur', 'Puri', 'Balasore', 'Bhadrak', 'Baripada', 'Jeypore'],
    'Punjab': ['Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala', 'Bathinda', 'Mohali', 'Pathankot', 'Hoshiarpur', 'Batala', 'Moga'],
    'Rajasthan': ['Jaipur', 'Jodhpur', 'Udaipur', 'Kota', 'Bikaner', 'Ajmer', 'Bhilwara', 'Alwar', 'Bharatpur', 'Sikar'],
    'Sikkim': ['Gangtok', 'Namchi', 'Mangan', 'Gyalshing', 'Ravangla', 'Pelling', 'Rangpo', 'Jorethang'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem', 'Tirunelveli', 'Tiruppur', 'Erode', 'Vellore', 'Thoothukudi'],
    'Telangana': ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar', 'Ramagundam', 'Khammam', 'Mahbubnagar', 'Nalgonda', 'Adilabad', 'Suryapet'],
    'Tripura': ['Agartala', 'Udaipur', 'Dharmanagar', 'Kailasahar', 'Belonia', 'Ambassa', 'Khowai', 'Sabroom'],
    'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Ghaziabad', 'Agra', 'Varanasi', 'Meerut', 'Allahabad', 'Bareilly', 'Aligarh', 'Moradabad'],
    'Uttarakhand': ['Dehradun', 'Haridwar', 'Roorkee', 'Haldwani', 'Rudrapur', 'Kashipur', 'Rishikesh', 'Pithoragarh', 'Ramnagar'],
    'West Bengal': ['Kolkata', 'Howrah', 'Durgapur', 'Asansol', 'Siliguri', 'Bardhaman', 'Malda', 'Baharampur', 'Habra', 'Kharagpur'],
    'Delhi': ['New Delhi', 'North Delhi', 'South Delhi', 'East Delhi', 'West Delhi', 'Central Delhi', 'Dwarka', 'Rohini', 'Saket', 'Karol Bagh'],
    'Jammu and Kashmir': ['Srinagar', 'Jammu', 'Anantnag', 'Baramulla', 'Sopore', 'Kathua', 'Udhampur', 'Kupwara', 'Budgam', 'Leh'],
    'Ladakh': ['Leh', 'Kargil', 'Nubra', 'Zanskar', 'Drass', 'Diskit', 'Padum'],
    'Puducherry': ['Puducherry', 'Karaikal', 'Yanam', 'Mahe', 'Ozhukarai', 'Villianur', 'Ariankuppam'],
  };

  // ── USA: States with major cities ───────────────────────────────────────────
  static const Map<String, List<String>> _usaStates = {
    'Alabama': ['Birmingham', 'Montgomery', 'Huntsville', 'Mobile', 'Tuscaloosa'],
    'Alaska': ['Anchorage', 'Fairbanks', 'Juneau', 'Sitka', 'Ketchikan'],
    'Arizona': ['Phoenix', 'Tucson', 'Mesa', 'Chandler', 'Scottsdale'],
    'California': ['Los Angeles', 'San Francisco', 'San Diego', 'San Jose', 'Sacramento'],
    'Florida': ['Miami', 'Orlando', 'Tampa', 'Jacksonville', 'Fort Lauderdale'],
    'Georgia': ['Atlanta', 'Augusta', 'Columbus', 'Savannah', 'Athens'],
    'Illinois': ['Chicago', 'Springfield', 'Naperville', 'Rockford', 'Aurora'],
    'New York': ['New York City', 'Buffalo', 'Rochester', 'Albany', 'Syracuse'],
    'Texas': ['Houston', 'Dallas', 'San Antonio', 'Austin', 'Fort Worth'],
    'Washington': ['Seattle', 'Spokane', 'Tacoma', 'Vancouver', 'Bellevue'],
  };

  // ── UK: Nations/Regions with cities ─────────────────────────────────────────
  static const Map<String, List<String>> _ukStates = {
    'England': ['London', 'Birmingham', 'Manchester', 'Leeds', 'Liverpool', 'Bristol', 'Sheffield', 'Newcastle', 'Nottingham', 'Leicester'],
    'Scotland': ['Edinburgh', 'Glasgow', 'Aberdeen', 'Dundee', 'Inverness', 'Stirling', 'Perth', 'Paisley'],
    'Wales': ['Cardiff', 'Swansea', 'Newport', 'Wrexham', 'Barry', 'Neath', 'Port Talbot'],
    'Northern Ireland': ['Belfast', 'Derry', 'Lisburn', 'Newry', 'Bangor', 'Craigavon', 'Coleraine'],
  };

  // ── UAE: Emirates with cities ──────────────────────────────────────────────
  static const Map<String, List<String>> _uaeStates = {
    'Abu Dhabi': ['Abu Dhabi', 'Al Ain', 'Madinat Zayed', 'Ruwais', 'Ghayathi'],
    'Dubai': ['Dubai', 'Jebel Ali', 'Hatta', 'Al Khail'],
    'Sharjah': ['Sharjah', 'Khor Fakkan', 'Kalba', 'Dibba Al-Hisn'],
    'Ajman': ['Ajman', 'Masfout', 'Manama'],
    'Umm Al Quwain': ['Umm Al Quwain'],
    'Ras Al Khaimah': ['Ras Al Khaimah', 'Digdaga', 'Ghalilah'],
    'Fujairah': ['Fujairah', 'Dibba', 'Masafi'],
  };

  // ── Pakistan: Provinces with cities ────────────────────────────────────────
  static const Map<String, List<String>> _pakistanStates = {
    'Punjab': ['Lahore', 'Faisalabad', 'Rawalpindi', 'Multan', 'Gujranwala', 'Sialkot', 'Bahawalpur', 'Sargodha'],
    'Sindh': ['Karachi', 'Hyderabad', 'Sukkur', 'Larkana', 'Nawabshah', 'Mirpur Khas'],
    'Khyber Pakhtunkhwa': ['Peshawar', 'Mardan', 'Mingora', 'Kohat', 'Abbottabad', 'Dera Ismail Khan'],
    'Balochistan': ['Quetta', 'Turbat', 'Khuzdar', 'Chaman', 'Gwadar', 'Sibi'],
    'Islamabad': ['Islamabad', 'Rawalpindi'],
    'Gilgit-Baltistan': ['Gilgit', 'Skardu', 'Hunza', 'Chilas'],
  };

  // ── Bangladesh: Divisions with cities ──────────────────────────────────────
  static const Map<String, List<String>> _bangladeshStates = {
    'Dhaka': ['Dhaka', 'Gazipur', 'Narayanganj', 'Tangail', 'Mymensingh', 'Jamalpur', 'Kishoreganj'],
    'Chittagong': ['Chittagong', 'Comilla', 'Cox\'s Bazar', 'Rangamati', 'Bandarban', 'Feni', 'Noakhali'],
    'Rajshahi': ['Rajshahi', 'Bogra', 'Pabna', 'Sirajganj', 'Naogaon', 'Natore', 'Chapainawabganj'],
    'Khulna': ['Khulna', 'Jessore', 'Satkhira', 'Bagerhat', 'Chuadanga', 'Jhenaidah', 'Magura'],
    'Barisal': ['Barisal', 'Patuakhali', 'Pirojpur', 'Bhola', 'Jhalokati', 'Barguna'],
    'Sylhet': ['Sylhet', 'Moulvibazar', 'Habiganj', 'Sunamganj'],
    'Rangpur': ['Rangpur', 'Dinajpur', 'Nilphamari', 'Lalmonirhat', 'Kurigram', 'Gaibandha', 'Thakurgaon'],
  };

  // ── Sri Lanka: Provinces with cities ────────────────────────────────────────
  static const Map<String, List<String>> _sriLankaStates = {
    'Western': ['Colombo', 'Gampaha', 'Kalutara', 'Negombo', 'Moratuwa', 'Panadura'],
    'Central': ['Kandy', 'Matale', 'Nuwara Eliya', 'Gampola', 'Dambulla', 'Hatton'],
    'Southern': ['Galle', 'Matara', 'Hambantota', 'Ambalangoda', 'Tangalle', 'Weligama'],
    'Northern': ['Jaffna', 'Vavuniya', 'Kilinochchi', 'Mullaitivu', 'Point Pedro'],
    'Eastern': ['Trincomalee', 'Batticaloa', 'Ampara', 'Kalmunai', 'Eravur'],
    'North Western': ['Kurunegala', 'Puttalam', 'Chilaw', 'Kuliyapitiya', 'Narammala'],
    'North Central': ['Anuradhapura', 'Polonnaruwa', 'Medawachchiya', 'Habarana'],
    'Uva': ['Badulla', 'Monaragala', 'Bandarawela', 'Haputale', 'Wellawaya'],
    'Sabaragamuwa': ['Ratnapura', 'Kegalle', 'Balangoda', 'Embilipitiya', 'Pelmadulla'],
  };

  // ── Nepal: Provinces with cities ────────────────────────────────────────────
  static const Map<String, List<String>> _nepalStates = {
    'Province 1': ['Biratnagar', 'Dharan', 'Itahari', 'Bhadrapur', 'Damak', 'Inaruwa', 'Biratnagar'],
    'Province 2': ['Janakpur', 'Birgunj', 'Rajbiraj', 'Lahan', 'Siraha', 'Malangwa', 'Gaur'],
    'Bagmati': ['Kathmandu', 'Lalitpur', 'Bhaktapur', 'Hetauda', 'Dhulikhel', 'Panauti', 'Banepa'],
    'Gandaki': ['Pokhara', 'Gorkha', 'Bharatpur', 'Syangja', 'Baglung', 'Kaski', 'Lamjung'],
    'Lumbini': ['Butwal', 'Nepalgunj', 'Tansen', 'Gulariya', 'Bhairahawa', 'Kapilvastu'],
    'Karnali': ['Birendranagar', 'Surkhet', 'Jumla', 'Dolpa', 'Manma', 'Dailekh'],
    'Sudurpashchim': ['Dhangaadhi', 'Mahendranagar', 'Tikapur', 'Dipayal', 'Baitadi', 'Dadeldhura'],
  };

  // ── Singapore: Single "state" with districts ────────────────────────────────
  static const Map<String, List<String>> _singaporeStates = {
    'Central': ['Orchard', 'Marina Bay', 'Bugis', 'Chinatown', 'Little India', 'Clarke Quay'],
    'East': ['Tampines', 'Bedok', 'Changi', 'Pasir Ris', 'Simei', 'Kembangan'],
    'West': ['Jurong', 'Clementi', 'Bukit Batok', 'Choa Chu Kang', 'Tuas', 'Pioneer'],
    'North': ['Woodlands', 'Yishun', 'Sembawang', 'Mandai', 'Admiralty'],
    'North-East': ['Serangoon', 'Hougang', 'Punggol', 'Sengkang', 'Kovan'],
  };

  // ── Malaysia: States with cities ───────────────────────────────────────────
  static const Map<String, List<String>> _malaysiaStates = {
    'Selangor': ['Shah Alam', 'Petaling Jaya', 'Klang', 'Subang Jaya', 'Ampang', 'Kajang', 'Rawang'],
    'Kuala Lumpur': ['Kuala Lumpur', 'Brickfields', 'Bukit Bintang', 'Cheras', 'Kepong', 'Setapak'],
    'Johor': ['Johor Bahru', 'Pasir Gudang', 'Muar', 'Batu Pahat', 'Kulai', 'Kluang', 'Segamat'],
    'Penang': ['George Town', 'Butterworth', 'Bayan Lepas', 'Batu Ferringhi', 'Air Itam'],
    'Perak': ['Ipoh', 'Taiping', 'Teluk Intan', 'Sungai Siput', 'Kampar', 'Batu Gajah'],
    'Kedah': ['Alor Setar', 'Sungai Petani', 'Kulim', 'Langkawi', 'Baling', 'Yan'],
    'Kelantan': ['Kota Bharu', 'Pasir Mas', 'Tanah Merah', 'Gua Musang', 'Kuala Krai'],
    'Terengganu': ['Kuala Terengganu', 'Kemaman', 'Dungun', 'Marang', 'Besut'],
    'Pahang': ['Kuantan', 'Temerloh', 'Bentong', 'Raub', 'Jerantut', 'Cameron Highlands'],
    'Sabah': ['Kota Kinabalu', 'Sandakan', 'Tawau', 'Lahad Datu', 'Keningau', 'Kudat'],
    'Sarawak': ['Kuching', 'Miri', 'Sibu', 'Bintulu', 'Sri Aman', 'Sarikei', 'Limbang'],
  };
}
