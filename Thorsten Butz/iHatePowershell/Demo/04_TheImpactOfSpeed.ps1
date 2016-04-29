$number04 = {
  'THE IMPACT OF SPEED HAS BEEN GREATLY EXAGGERATED'  
}

# How many items do you want to add to your collections (array, arrayList)? 
$count = 20000 # Try 10.000 items (or less) first!

#region Arraylist

    [System.Collections.ArrayList]$al = @()

    $durationAl = (Measure-Command {
        foreach ($i in 1..$count) {
          $test = Get-Random
          $al.Add($test)
          }
    }).TotalSeconds 
    "Adding $($al.count) elements to an arraylist took {0:0.000} seconds." -f $durationAl

#endregion

#region Array 

    [array]$arr = @()
    $durationArr = (Measure-Command {
        foreach ($i in 1..$count) {
          $test = Get-Random
          $arr += $test
          }
    }).TotalSeconds
    "Adding $($arr.count) elements to an array took {0:0.000} seconds." -f $durationArr

#endregion

#region What's the problem with arrays?
 
    #"`nArrayList.fixedsize" + $al.IsFixedSize
    #"`nArray.fixedsize" +  $arr.IsFixedSize

#endregion