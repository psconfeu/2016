$number09 = {
  'LOST IN TRANSLATION' # -replace vs .replace
}


#region TEST 1

    'Thomas Müller' -replace 'ü','ue'
    'Thomas Müller'.replace('ü','ue')

#endregion

#region TEST 2

    'Mesut Özil' -replace 'ö','oe'
    'Mesut Özil'.replace('ö','oe')

#endregion

#region TEST 3

    'Mesut Özil' -creplace '\bÖ','Oe'
    'Mesut Özil'.replace('\bÖ','Oe')

    'Mario Götze' -creplace '\bö','oe'
    'Mario Götze'.replace('\bö','oe')

#endregion