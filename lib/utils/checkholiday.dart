import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> isPublicHoliday(DateTime date) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  
  // Extract year, month, and day from the provided date
  int year = date.year;
  int month = date.month;
  int day = date.day;

  // Get cached yearly public holidays
  Map<String, List<DateTime>>? yearlyHolidays = await getCachedYearlyPublicHolidays(year);

  bool containsMonth = yearlyHolidays != null && yearlyHolidays.containsKey(month.toString());
  print('Does yearlyHolidays contain month $month? $containsMonth');

  if (containsMonth) {
    List<DateTime> holidays = yearlyHolidays[month.toString()]!;
      
    // Check if the provided date matches any of the holiday dates for that day
    bool isHoliday = holidays.any((holidayDate) => holidayDate.day == day);
    
    
    // Print out the fetched data and if the date is a holiday
    print('Fetched data for year $year and month $month: $yearlyHolidays');
    print('Is $date a holiday? $isHoliday');
    // Log that the if statement was executed
    print('If statement executed');
    
    return isHoliday;

  }

  return false; // If there's no cached data or the date is not a holiday
}

Future<Map<String, List<DateTime>>?> getCachedYearlyPublicHolidays(int year) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String key = 'yearlyHolidays_$year';
  if (prefs.containsKey(key)) {
    String? jsonData = prefs.getString(key);
    if (jsonData != null) {
      Map<String, dynamic> yearlyHolidaysData = json.decode(jsonData);
      print('Cached holidays for $year retrieved from SharedPreferences');
      try {
          Map<String, List<DateTime>> cachedHolidays = yearlyHolidaysData.map((key, value) {
            String month = key;
            List<DateTime> monthHolidayDates = (value as List<dynamic>)
              .map((dateStr) => DateTime.parse(dateStr.toString()))
              .toList();
          return MapEntry(month, monthHolidayDates);
        });
        // Log the cached data before returning
        print('Cached holidays for $year retrieved from SharedPreferences: $cachedHolidays');
        return cachedHolidays;
      } catch (e) {
        print("Error parsing dates: $e");
        return null;
      }
    }
  }

  // If the data is not cached for the specific year, fetch and cache it
  Map<String, List<DateTime>>? fetchedHolidays = await fetchAndCacheYearlyPublicHolidays(year);
  return fetchedHolidays;
}

Future<Map<String, List<DateTime>>?> fetchAndCacheYearlyPublicHolidays(int year) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String country = 'mys'; // Canada.
  String apiKey = '7NptmBIBjVj5yrWzjfzZtw==0NPykd4YNC5ycVzU';
  String yearString = year.toString(); // Convert int year to string
  
  String apiUrl = 'https://api.api-ninjas.com/v1/holidays?country=$country&year=$year';

  Map<String, String> headers = {
    'X-Api-Key': apiKey,
  };

try {
  http.Response response = await http.get(Uri.parse(apiUrl), headers: headers);

  try {
    if (response.statusCode == 200) {
      List<dynamic> decodedData = json.decode(response.body);

      // Filter the decoded data for specific holiday types
      List<dynamic> filteredHolidays = decodedData.where((holiday) =>
          holiday['type'] == 'FEDERAL_PUBLIC_HOLIDAY' || holiday['type'] == 'COMMON_LOCAL_HOLIDAY')
          .toList();

    
      // Map to store holidays for each day of the year
      Map<String, List<String>> cachedyearlyHolidays = {};
      Map<String, List<DateTime>> yearlyHolidays = {};

      try {
        for (var holiday in filteredHolidays) {
          DateTime holidayDate = DateTime.parse(holiday['date']);
          String month = holidayDate.month.toString();

          if (!cachedyearlyHolidays.containsKey(month)) {
            cachedyearlyHolidays[month] = [];
            yearlyHolidays[month] = [];
          }
          yearlyHolidays[month]!.add(holidayDate);
          cachedyearlyHolidays[month]!.add(holidayDate.toIso8601String());
        }

        // Cache the fetched data for the entire year
        await prefs.setString('yearlyHolidays_$year', json.encode(cachedyearlyHolidays));
        print('Fetched and cached holidays for $year ${response.body}'); // Log successful fetch

        return yearlyHolidays;
      } catch (e) {
        print('Error in holiday processing: $e');
      }

    } else {
        print('Error: No "response" key found in the API response');
      }
  } catch (e) {
    print('Error in response processing: $e');
  }
} catch (e) {
  print('Error in HTTP request: $e');
}
return null; // Return null if there's an error or no holiday data fetched
}

void printCachedYearlyHolidays(int year) async {
  Map<String, List<DateTime>>? cachedData = await getCachedYearlyPublicHolidays(year);
  if (cachedData != null) {
    cachedData.forEach((month, holidays) {
      print('Year: $year, Month: $month, Holidays: $holidays');
    });
  } else {
    print('No cached data found for year $year');
  }
}
