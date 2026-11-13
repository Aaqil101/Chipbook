/// An ISO 4217 currency the app can record entries in.
class Currency {
  const Currency(this.code, this.name, {this.decimalDigits = 2});

  /// Three-letter ISO 4217 code.
  final String code;

  /// English display name used by the currency pickers.
  final String name;

  /// Number of digits after the decimal separator.
  final int decimalDigits;

  String get label => '$code · $name';
}

/// The fiat currencies Chipbook accepts.
///
/// Fraction digits come from ISO 4217: most currencies use two, but yen and
/// several others use none, while a handful of dinars use three. Keeping the
/// catalog local means parsing and formatting never have to guess.
abstract final class CurrencyCatalog {
  static const List<Currency> currencies = <Currency>[
    Currency('AED', 'UAE Dirham'),
    Currency('AFN', 'Afghan Afghani'),
    Currency('ALL', 'Albanian Lek'),
    Currency('AMD', 'Armenian Dram'),
    Currency('ANG', 'Netherlands Antillean Guilder'),
    Currency('AOA', 'Angolan Kwanza'),
    Currency('ARS', 'Argentine Peso'),
    Currency('AUD', 'Australian Dollar'),
    Currency('AWG', 'Aruban Florin'),
    Currency('AZN', 'Azerbaijani Manat'),
    Currency('BAM', 'Bosnia-Herzegovina Convertible Mark'),
    Currency('BBD', 'Barbadian Dollar'),
    Currency('BDT', 'Bangladeshi Taka'),
    Currency('BGN', 'Bulgarian Lev'),
    Currency('BHD', 'Bahraini Dinar', decimalDigits: 3),
    Currency('BIF', 'Burundian Franc', decimalDigits: 0),
    Currency('BMD', 'Bermudan Dollar'),
    Currency('BND', 'Brunei Dollar'),
    Currency('BOB', 'Bolivian Boliviano'),
    Currency('BRL', 'Brazilian Real'),
    Currency('BSD', 'Bahamian Dollar'),
    Currency('BTN', 'Bhutanese Ngultrum'),
    Currency('BWP', 'Botswana Pula'),
    Currency('BYN', 'Belarusian Ruble'),
    Currency('BZD', 'Belize Dollar'),
    Currency('CAD', 'Canadian Dollar'),
    Currency('CDF', 'Congolese Franc'),
    Currency('CHF', 'Swiss Franc'),
    Currency('CLP', 'Chilean Peso', decimalDigits: 0),
    Currency('CNY', 'Chinese Yuan'),
    Currency('COP', 'Colombian Peso'),
    Currency('CRC', 'Costa Rican Colón'),
    Currency('CUP', 'Cuban Peso'),
    Currency('CVE', 'Cape Verdean Escudo'),
    Currency('CZK', 'Czech Koruna'),
    Currency('DJF', 'Djiboutian Franc', decimalDigits: 0),
    Currency('DKK', 'Danish Krone'),
    Currency('DOP', 'Dominican Peso'),
    Currency('DZD', 'Algerian Dinar'),
    Currency('EGP', 'Egyptian Pound'),
    Currency('ERN', 'Eritrean Nakfa'),
    Currency('ETB', 'Ethiopian Birr'),
    Currency('EUR', 'Euro'),
    Currency('FJD', 'Fijian Dollar'),
    Currency('FKP', 'Falkland Islands Pound'),
    Currency('GBP', 'British Pound'),
    Currency('GEL', 'Georgian Lari'),
    Currency('GHS', 'Ghanaian Cedi'),
    Currency('GIP', 'Gibraltar Pound'),
    Currency('GMD', 'Gambian Dalasi'),
    Currency('GNF', 'Guinean Franc', decimalDigits: 0),
    Currency('GTQ', 'Guatemalan Quetzal'),
    Currency('GYD', 'Guyanese Dollar'),
    Currency('HKD', 'Hong Kong Dollar'),
    Currency('HNL', 'Honduran Lempira'),
    Currency('HTG', 'Haitian Gourde'),
    Currency('HUF', 'Hungarian Forint'),
    Currency('IDR', 'Indonesian Rupiah'),
    Currency('ILS', 'Israeli New Shekel'),
    Currency('INR', 'Indian Rupee'),
    Currency('IQD', 'Iraqi Dinar', decimalDigits: 3),
    Currency('IRR', 'Iranian Rial'),
    Currency('ISK', 'Icelandic Króna', decimalDigits: 0),
    Currency('JMD', 'Jamaican Dollar'),
    Currency('JOD', 'Jordanian Dinar', decimalDigits: 3),
    Currency('JPY', 'Japanese Yen', decimalDigits: 0),
    Currency('KES', 'Kenyan Shilling'),
    Currency('KGS', 'Kyrgyzstani Som'),
    Currency('KHR', 'Cambodian Riel'),
    Currency('KMF', 'Comorian Franc', decimalDigits: 0),
    Currency('KPW', 'North Korean Won'),
    Currency('KRW', 'South Korean Won', decimalDigits: 0),
    Currency('KWD', 'Kuwaiti Dinar', decimalDigits: 3),
    Currency('KYD', 'Cayman Islands Dollar'),
    Currency('KZT', 'Kazakhstani Tenge'),
    Currency('LAK', 'Lao Kip'),
    Currency('LBP', 'Lebanese Pound'),
    Currency('LKR', 'Sri Lankan Rupee'),
    Currency('LRD', 'Liberian Dollar'),
    Currency('LSL', 'Lesotho Loti'),
    Currency('LYD', 'Libyan Dinar', decimalDigits: 3),
    Currency('MAD', 'Moroccan Dirham'),
    Currency('MDL', 'Moldovan Leu'),
    Currency('MGA', 'Malagasy Ariary'),
    Currency('MKD', 'Macedonian Denar'),
    Currency('MMK', 'Myanmar Kyat'),
    Currency('MNT', 'Mongolian Tögrög'),
    Currency('MOP', 'Macanese Pataca'),
    Currency('MRU', 'Mauritanian Ouguiya'),
    Currency('MUR', 'Mauritian Rupee'),
    Currency('MVR', 'Maldivian Rufiyaa'),
    Currency('MWK', 'Malawian Kwacha'),
    Currency('MXN', 'Mexican Peso'),
    Currency('MYR', 'Malaysian Ringgit'),
    Currency('MZN', 'Mozambican Metical'),
    Currency('NAD', 'Namibian Dollar'),
    Currency('NGN', 'Nigerian Naira'),
    Currency('NIO', 'Nicaraguan Córdoba'),
    Currency('NOK', 'Norwegian Krone'),
    Currency('NPR', 'Nepalese Rupee'),
    Currency('NZD', 'New Zealand Dollar'),
    Currency('OMR', 'Omani Rial', decimalDigits: 3),
    Currency('PAB', 'Panamanian Balboa'),
    Currency('PEN', 'Peruvian Sol'),
    Currency('PGK', 'Papua New Guinean Kina'),
    Currency('PHP', 'Philippine Peso'),
    Currency('PKR', 'Pakistani Rupee'),
    Currency('PLN', 'Polish Złoty'),
    Currency('PYG', 'Paraguayan Guaraní', decimalDigits: 0),
    Currency('QAR', 'Qatari Riyal'),
    Currency('RON', 'Romanian Leu'),
    Currency('RSD', 'Serbian Dinar'),
    Currency('RUB', 'Russian Ruble'),
    Currency('RWF', 'Rwandan Franc', decimalDigits: 0),
    Currency('SAR', 'Saudi Riyal'),
    Currency('SBD', 'Solomon Islands Dollar'),
    Currency('SCR', 'Seychellois Rupee'),
    Currency('SDG', 'Sudanese Pound'),
    Currency('SEK', 'Swedish Krona'),
    Currency('SGD', 'Singapore Dollar'),
    Currency('SHP', 'Saint Helena Pound'),
    Currency('SLE', 'Sierra Leonean Leone'),
    Currency('SOS', 'Somali Shilling'),
    Currency('SRD', 'Surinamese Dollar'),
    Currency('SSP', 'South Sudanese Pound'),
    Currency('STN', 'São Tomé and Príncipe Dobra'),
    Currency('SVC', 'Salvadoran Colón'),
    Currency('SYP', 'Syrian Pound'),
    Currency('SZL', 'Eswatini Lilangeni'),
    Currency('THB', 'Thai Baht'),
    Currency('TJS', 'Tajikistani Somoni'),
    Currency('TMT', 'Turkmenistani Manat'),
    Currency('TND', 'Tunisian Dinar', decimalDigits: 3),
    Currency('TOP', 'Tongan Paʻanga'),
    Currency('TRY', 'Turkish Lira'),
    Currency('TTD', 'Trinidad and Tobago Dollar'),
    Currency('TWD', 'New Taiwan Dollar'),
    Currency('TZS', 'Tanzanian Shilling'),
    Currency('UAH', 'Ukrainian Hryvnia'),
    Currency('UGX', 'Ugandan Shilling', decimalDigits: 0),
    Currency('USD', 'US Dollar'),
    Currency('UYU', 'Uruguayan Peso'),
    Currency('UZS', 'Uzbekistani Som'),
    Currency('VED', 'Venezuelan Digital Bolívar'),
    Currency('VES', 'Venezuelan Bolívar'),
    Currency('VND', 'Vietnamese Đồng', decimalDigits: 0),
    Currency('VUV', 'Vanuatu Vatu', decimalDigits: 0),
    Currency('WST', 'Samoan Tālā'),
    Currency('XAF', 'Central African CFA Franc', decimalDigits: 0),
    Currency('XCD', 'East Caribbean Dollar'),
    Currency('XCG', 'Caribbean Guilder'),
    Currency('XOF', 'West African CFA Franc', decimalDigits: 0),
    Currency('XPF', 'CFP Franc', decimalDigits: 0),
    Currency('YER', 'Yemeni Rial'),
    Currency('ZAR', 'South African Rand'),
    Currency('ZMW', 'Zambian Kwacha'),
    Currency('ZWG', 'Zimbabwe Gold'),
  ];

  static final Map<String, Currency> _byCode = {
    for (final currency in currencies) currency.code: currency,
  };

  /// Looks up [code] case-insensitively, or returns null for unknown codes.
  static Currency? byCode(String code) => _byCode[code.trim().toUpperCase()];

  /// Currencies whose code or name contains [query], case-insensitively.
  ///
  /// An empty query returns the whole catalog in its original order.
  static List<Currency> search(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return currencies;
    }
    return currencies
        .where(
          (currency) =>
              currency.code.toLowerCase().contains(needle) ||
              currency.name.toLowerCase().contains(needle),
        )
        .toList(growable: false);
  }

  /// ISO 4217 fraction digits for [code], defaulting to two when unknown.
  static int fractionDigitsFor(String code) => byCode(code)?.decimalDigits ?? 2;
}
