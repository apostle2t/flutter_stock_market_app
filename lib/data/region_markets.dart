/// A company in a region's watchlist.
///
/// [yahooSymbol] is what we query Yahoo with (often exchange-suffixed, e.g.
/// `SAP.DE`); [symbol] and [name] are what we display.
class RegionStock {
  const RegionStock(this.yahooSymbol, this.symbol, this.name);
  final String yahooSymbol;
  final String symbol;
  final String name;
}

/// The market profile shown for a detected region: a human label for the
/// exchanges and a watchlist of that region's major listed companies.
class RegionMarket {
  const RegionMarket({required this.exchangeLabel, required this.stocks});
  final String exchangeLabel;
  final List<RegionStock> stocks;
}

/// Maps an ISO country code to its market profile. Falls back to the US.
RegionMarket regionFor(String? countryCode) =>
    _markets[(countryCode ?? '').toUpperCase()] ?? _markets['US']!;

const Map<String, RegionMarket> _markets = {
  'US': RegionMarket(
    exchangeLabel: 'NYSE  ·  NASDAQ',
    stocks: [
      RegionStock('AAPL', 'AAPL', 'Apple Inc.'),
      RegionStock('MSFT', 'MSFT', 'Microsoft Corp.'),
      RegionStock('NVDA', 'NVDA', 'NVIDIA Corp.'),
      RegionStock('TSLA', 'TSLA', 'Tesla, Inc.'),
      RegionStock('GOOGL', 'GOOGL', 'Alphabet Inc.'),
    ],
  ),
  'DE': RegionMarket(
    exchangeLabel: 'XETRA  ·  Frankfurt',
    stocks: [
      RegionStock('SAP.DE', 'SAP', 'SAP SE'),
      RegionStock('SIE.DE', 'SIE', 'Siemens AG'),
      RegionStock('VOW3.DE', 'VOW3', 'Volkswagen AG'),
      RegionStock('ALV.DE', 'ALV', 'Allianz SE'),
      RegionStock('MBG.DE', 'MBG', 'Mercedes-Benz Group'),
    ],
  ),
  'GB': RegionMarket(
    exchangeLabel: 'London Stock Exchange',
    stocks: [
      RegionStock('SHEL.L', 'SHEL', 'Shell plc'),
      RegionStock('AZN.L', 'AZN', 'AstraZeneca plc'),
      RegionStock('HSBA.L', 'HSBA', 'HSBC Holdings'),
      RegionStock('BP.L', 'BP', 'BP plc'),
      RegionStock('ULVR.L', 'ULVR', 'Unilever plc'),
    ],
  ),
  'FR': RegionMarket(
    exchangeLabel: 'Euronext Paris',
    stocks: [
      RegionStock('MC.PA', 'MC', 'LVMH'),
      RegionStock('OR.PA', 'OR', "L'Oréal"),
      RegionStock('AIR.PA', 'AIR', 'Airbus SE'),
      RegionStock('TTE.PA', 'TTE', 'TotalEnergies'),
      RegionStock('SAN.PA', 'SAN', 'Sanofi'),
    ],
  ),
  'NL': RegionMarket(
    exchangeLabel: 'Euronext Amsterdam',
    stocks: [
      RegionStock('ASML.AS', 'ASML', 'ASML Holding'),
      RegionStock('AD.AS', 'AD', 'Ahold Delhaize'),
      RegionStock('INGA.AS', 'INGA', 'ING Groep'),
      RegionStock('PHIA.AS', 'PHIA', 'Philips'),
      RegionStock('HEIA.AS', 'HEIA', 'Heineken'),
    ],
  ),
  'JP': RegionMarket(
    exchangeLabel: 'Tokyo Stock Exchange',
    stocks: [
      RegionStock('7203.T', '7203', 'Toyota Motor'),
      RegionStock('6758.T', '6758', 'Sony Group'),
      RegionStock('9984.T', '9984', 'SoftBank Group'),
      RegionStock('6861.T', '6861', 'Keyence Corp.'),
      RegionStock('8306.T', '8306', 'Mitsubishi UFJ'),
    ],
  ),
  'CA': RegionMarket(
    exchangeLabel: 'Toronto Stock Exchange',
    stocks: [
      RegionStock('RY.TO', 'RY', 'Royal Bank of Canada'),
      RegionStock('TD.TO', 'TD', 'TD Bank'),
      RegionStock('SHOP.TO', 'SHOP', 'Shopify Inc.'),
      RegionStock('ENB.TO', 'ENB', 'Enbridge Inc.'),
      RegionStock('CNR.TO', 'CNR', 'Canadian National'),
    ],
  ),
  'IN': RegionMarket(
    exchangeLabel: 'NSE  ·  BSE',
    stocks: [
      RegionStock('RELIANCE.NS', 'RELIANCE', 'Reliance Industries'),
      RegionStock('TCS.NS', 'TCS', 'Tata Consultancy'),
      RegionStock('INFY.NS', 'INFY', 'Infosys'),
      RegionStock('HDFCBANK.NS', 'HDFCBANK', 'HDFC Bank'),
      RegionStock('ICICIBANK.NS', 'ICICIBANK', 'ICICI Bank'),
    ],
  ),
  'AU': RegionMarket(
    exchangeLabel: 'Australian Securities Exchange',
    stocks: [
      RegionStock('BHP.AX', 'BHP', 'BHP Group'),
      RegionStock('CBA.AX', 'CBA', 'Commonwealth Bank'),
      RegionStock('CSL.AX', 'CSL', 'CSL Limited'),
      RegionStock('NAB.AX', 'NAB', 'National Australia Bank'),
      RegionStock('WBC.AX', 'WBC', 'Westpac Banking'),
    ],
  ),
};
