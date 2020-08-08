<?php  

$alias=file_get_contents("http://localhost:27876/nxt?requestType=getAlias&chain=2&aliasName=ArdorPi");
$alias_obj = json_decode($alias);
$alias_array = explode("|",$alias_obj->aliasURI);

 if (isset($_GET["update"])) {

  //$update_file=file_get_contents("http://localhost:27876/nxt?requestType=downloadTaggedData&chain=2&transactionFullHash=".$alias_array[1]);
  $f = file_put_contents("update.zip", fopen("http://localhost:27876/nxt?requestType=downloadTaggedData&chain=2&transactionFullHash=".$alias_array[1], 'r'), LOCK_EX);
  if(FALSE === $f)
      die("Couldn't write to file.");
  $zip = new ZipArchive;
  $res = $zip->open('update.zip');
  if ($res === TRUE) {
    $zip->extractTo('.');
    $zip->close();
    $output = "Updated";
    header("Location: update.php");
  } else {
    $output = "Error";
  }
 }
 else if(isset($_POST["btn_zip"]))  
 {  
      $output = 'Uploading';  
      if($_FILES['zip_file']['name'] != '')  
      {  
           $file_name = $_FILES['zip_file']['name'];  
           $array = explode(".", $file_name);  
           $name = $array[0];  
           $ext = $array[1];  
           if($ext == 'zip')  
           {
                $path = '.'; //Example 'upload/' 
                $location = $path . $file_name;
                if(move_uploaded_file($_FILES['zip_file']['tmp_name'], $location))  
                {
                     $zip = new ZipArchive;
                     if($zip->open($location))  
                     {
                          $zip->extractTo($path);  
                          $zip->close();  
                          $output = 'Updated'; 
                     }  
                     unlink($location);  
                }  
           }  
      }  
 }  
 ?>  
 <!DOCTYPE html>  
 <html>  
      <head>  
           <title>Upload Update</title>  
           <style>
              body {
                font-family: "Source Sans Pro", Helvetica, sans-serif;
              }
              form {
                margin-top: 5em;
              }
              .container {
                margin: auto;
              }
              .btn {
                background-color: #0e436d;
                border: 2px solid #0e436d;
                border-radius: 5px;
                color: white;
                padding: 7px 15px;
                text-align: center;
                text-decoration: none;
                display: inline-block;
                font-size: 12px;
              }
              .large {
                font-size: 18px;
                padding: 10px 25px;
              }
              #latest, #current {
                font-weight: bold;
              }
           </style>
      </head>  
      <body>  
           <br />  
           <div class="container" style="width:500px;">  
                <h1>Update ArdorPi</h1>
                <p>Current Version: <span id="current">0.1.1</span></p>
                <p>Latest Version: <span id="latest"><?=$alias_array[0] ?></span> <a href="#" onclick="alert('Changelog:\r\n<?=$alias_array[2] ?>')">?</a></p>
                <a class="btn large"  href="update.php?update">Update</a>

                <form method="post" enctype="multipart/form-data">  
                     <h4>Manual Update</h4>
                     <input type="file" name="zip_file" />  
                     <br /> <br />
                     <input type="submit" name="btn_zip" class="btn" value="Upload" />  
                </form>  
                <br />  
                <?php  
                if(isset($output))  
                {  
                     echo $output;  
                }  
                ?> 
           </div>
           <script src="assets/js/jquery-3.5.1.min.js"></script>
           <script>
              if ($("#latest").text() == $("#current").text()) {
                $("#current").css("color", "green");
              } else {
                $("#current").css("color", "red");
              }
            </script>
      </body>  
 </html>