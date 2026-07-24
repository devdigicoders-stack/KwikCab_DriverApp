const fs = require('fs');
const path = require('path');

const target = "import 'package:http/http.dart' as http;";
const replacement = "import 'package:kwikcabdriver/core/network/app_http.dart' as http;";
const dir = "c:\\Users\\vivekvkraj\\OneDrive\\Desktop\\Cab booking\\kwikcabdriver\\kwikcabdriver\\lib";

function walkDir(dirPath) {
    fs.readdirSync(dirPath).forEach(file => {
        let fullPath = path.join(dirPath, file);
        if (fs.statSync(fullPath).isDirectory()) {
            walkDir(fullPath);
        } else if (fullPath.endsWith('.dart')) {
            let content = fs.readFileSync(fullPath, 'utf8');
            if (content.includes(target)) {
                fs.writeFileSync(fullPath, content.replaceAll(target, replacement), 'utf8');
                console.log('Updated: ' + fullPath);
            }
        }
    });
}
walkDir(dir);
