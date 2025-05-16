<?php
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Open the folder on the server
    $path = 'C:\xampp\htdocs';
    shell_exec('start "" "' . $path . '"');
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Hello World</title>
    <style>
        body {
            font-family: system-ui;
            background: #f06d06;
            color: white;
            text-align: center;
            font-size: 3vw;
            margin-top: 100px;
        }

        button {
            font-size: 1.5vw;
            padding: 10px 20px;
            margin-top: 30px;
            background-color: white;
            color: #f06d06;
            border: none;
            border-radius: 8px;
            cursor: pointer;
        }

        button:hover {
            background-color: #f3f3f3;
        }
    </style>
</head>
<body>

    <h1>👋 Hello World!</h1>

    <form method="post">
        <button type="submit">Open htdocs Folder</button>
    </form>

</body>
</html>
