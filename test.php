<?php
$mysqli=new mysqli("127.0.0.1","root","");
if(mysqli_connect_errno()){
echo "连接数据库失败！LNMP部署失败。";
$mysqli=null;
exit;
}
echo "连接数据库成功！LNMP可以使用。";
$mysqli->close();
?>

