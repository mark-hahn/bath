var page = require('webpage').create();
page.open('http://www.wunderground.com/history/airport/KLGB/2014/11/23/MonthlyHistory.html#calendar', function() {
  page.render('phantom-test.png');
  phantom.exit();
});