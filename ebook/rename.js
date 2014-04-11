/*
 * A node.js script to rename a ebook file by given isdn.

 * Google Book API:
 * https://www.googleapis.com/books/v1/volumes?q=isbn:<your_isbn_here>
 * https://www.googleapis.com/books/v1/volumes?q=isbn:1617290572
 */
'use strict'; //strict mode 
var util = require('util');
var request = require('request');
var fs = require('fs');
var path = require('path');
var cheerio = require('cheerio');
var child_process = require('child_process');
var echo = console.log;


/* Consts*/
var homedir = (process.platform === 'win32') ? process.env.USERPROFILE : process.env.HOME;
//echo (homedir)
//var BOOK_SAVE_PATH="C:\\Users\\yidwu\\Downloads\\_Un"
var BOOK_SAVE_PATH=path.join(homedir,"Downloads","_Un"); //cross-platform path
/* Regxp */
var DATE_REGXP=/(January|February|March|April|May|June|July|August|September|October|November|December).*/
var ISBN10_REGXP=/^\d{9}[\d|X]/
var ISBN13_REGXP=/^(978|979)(?:-|)\d{9}[\d|X]/
var EDTION_REGXP=/^\d{1}$/
var ASIN_REGXP=/^[A-Z0-9]{10}/

function requestByGoogleBook(changeNameJob,isbn){
    var reqBody = {
        method:'GET',
        uri: 'https://www.googleapis.com/books/v1/volumes?q=isbn:' + isbn
    };
    request(reqBody,function(err,rep,body){
        if(rep.statusCode == 200){
            
            var jsObject = JSON.parse(body);
            echo("------------------------------------------------------------")
            echo(reqBody.uri)
            var newName = [];
            if (jsObject.items == undefined) {
                echo ('Error :'+isbn+", no result found!")
                return
            }
            var title=jsObject.items[0].volumeInfo.title.trim();
            var subtitle=jsObject.items[0].volumeInfo.subtitle;
            var date=jsObject.items[0].volumeInfo.publishedDate.trim();
            
            if (subtitle != undefined) title = title+" - "+subtitle.trim();
            newName.push(title);
            newName.push(date.substr(0,7));
            newName.push(isbn);
            newName = newName.join(", ");

            echo("Title    :",title);
            echo("Pub Date :",date);
            echo("New Name :",newName)

            if (date !== undefined) {
                changeNameJob.pubdate = new Date(Date.parse(date));
            }
            changeNameJob.changeName(newName);
        }else{
            echo('error :',rep.statusCode);
            echo(body);

        } 
    });
}

//requestByIsbn(doBookName,'1617290572');   

function requestByAmazon(changeNameJob,ASIN){
    var reqBody = {
        method:'GET',
        uri: 'http://www.amazon.com/dp/' + ASIN
    };
    request(reqBody,function(err,rep,body){
        if(rep.statusCode == 200){
            echo("------------------------------------------------------------")
            echo(reqBody.uri)
            var $ = cheerio.load(body);
            var newName = [];
            var title="";
            var type ="";
            if ($('#btAsinTitle').children().get(0)!==undefined){
                title = $('#btAsinTitle').children().get(0).prev.data.trim();
                type  = $('#btAsinTitle').children().text().trim();
            }else if($('#productTitle').text()!==undefined){
                title = $('#productTitle').text();
            }
            title = title.replace(/:/g," -");
            title = title.replace(/\//g,"&")
            
            var date
            var pubdate = $('#pubdate').val();

            if (pubdate === undefined) {
                $('div[class=buying]').find('span[style="font-weight: bold;"]').each(function() {
                    //echo("----------------")
                    var text = $(this).text().trim();
                    //echo(text);
                    if (DATE_REGXP.test(text)){
                        echo("Pub Date :",text);
                        pubdate = Date.parse(text);
                    }else if (ISBN13_REGXP.test(text)){
                        echo("ISDN_13  :",text);
                    }
                    else if(ISBN10_REGXP.test(text)){
                        echo("ISDN_10  :",text);
                    }else if(EDTION_REGXP.test(text)){
                        echo("Edtion   :",text);
                    }
                    
                });
            }
            if (pubdate !== undefined) {
                date = new Date(pubdate);
                //Notice, getMonth return 0 to 11
                var month= date.getMonth()+1
                date = (month<10) ? date.getFullYear()+"-0"+month
                                            : date.getFullYear()+"-"+month;
            }
            
            newName.push(title);
            newName.push(date);
            newName.push(ASIN);
            newName = newName.join(", ")

            echo("Type     :",type)
            echo("Title    :",title);
            echo("New Name :",newName)

            if (pubdate !== undefined) {
                changeNameJob.pubdate = pubdate
            }
            changeNameJob.changeName(newName);
        }else{
            echo("------------------------------------------------------------")
            echo("Fail to query",reqBody.uri);
            echo("Error :",rep.statusCode);
            echo("Try to use googlebook API");
            requestByGoogleBook(changeNameJob,ASIN);
        }
    });
}

function ChangeNameJob(parentDir,orginalFileName,fileExt){
    this.parentDir=parentDir;
    this.fileName=orginalFileName;
    this.fileExt=fileExt;
}
ChangeNameJob.prototype.changeName = function (newName){
    //check existed
    if (fs.existsSync(path.join(this.parentDir,newName+this.fileExt))) {
        newName = newName+"_"+Date.now();;
        echo("WARNING:","File exists!","->",newName+this.fileExt);

    }
    if(this.pubdate !== undefined){
        echo("Change file date to","->",new Date(this.pubdate).toDateString());
        fs.utimesSync(path.join(this.parentDir,this.fileName), this.pubdate/1000, this.pubdate/1000);
    }
    if(this.fileExt === ".zip"){ // code
        newName = newName+"[Source_Code]"
    }
    echo("Change file name ",this.fileName,"->",newName+this.fileExt);
    fs.rename(
        path.join(this.parentDir,this.fileName),
        path.join(this.parentDir,newName+this.fileExt),
        function (err) {
            if (err) echo('rename callback ', err); 
        });
    
}

function parseISBN(name){
    //echo("parseISBN",name)
    var isbn
    if (ISBN13_REGXP.test(name)) {    
        isbn=ISBN13_REGXP.exec(name)[0];
    }
    else if (ISBN10_REGXP.test(name)){
        isbn = ISBN10_REGXP.exec(name)[0];
    }
    else if (ASIN_REGXP.test(name)) { 
        isbn=ASIN_REGXP.exec(name)[0];
    }
    return isbn;
}

function renameBook(parentDir,file){
    //echo("enter",parentDir,file);
    if (!fs.statSync(path.join(parentDir,file)).isDirectory()){
        var fileName=file;
        var fileExt=path.extname(fileName);
        var fileBaseName=path.basename(fileName,fileExt);

        var isbn = parseISBN(fileBaseName);
        if (isbn === undefined){
            isbn = parseISBN(path.basename(parentDir));
        }
        if (isbn === undefined){
            echo("WARNING :","Can't parse a isdn or asin from given name : [",fileName,"]");
            return;
        }
        if (fileExt===".rar"){
            //uncompressRarFile(fileName,isbn);
            
        }else{
            echo("ChangeNameJob [","dir:'",parentDir,"'; file:'",fileName,"'; file-ext:'",fileExt,"'']");
            var job = new ChangeNameJob(parentDir,fileName,fileExt);
            requestByAmazon(job,isbn);
        }

    }else{
        //echo("folder",file);
        var isbn = parseISBN(file);
        if (isbn === undefined){
            echo("WARNING :","Can't parse a isdn or asin from given name : [",fileName,"]");
            return;
        }
        //echo("isbn",isbn)
        fs.readdir(path.join(parentDir,isbn),
                function(err,unzipfiles){
                    unzipfiles.forEach(function(unzipfile){
                        //echo("In isbn folder file",unzipfile);
                        renameBook(path.join(parentDir,isbn),unzipfile)})});
    }
}

function uncompressRarFile(rarfile,isbn){
    if (fs.statSync(path.join(BOOK_SAVE_PATH,rarfile)).isDirectory()) return;
    var fileExt=path.extname(rarfile);
    if (fileExt === ".rar") {
        var outputDir=path.join(BOOK_SAVE_PATH,isbn);
        var rarfilePath = path.join(BOOK_SAVE_PATH,rarfile);
        var _7zCmd = "7z x -o"+outputDir+" "+rarfilePath+" -y";
        echo(_7zCmd);
        child_process.exec(_7zCmd, function (error, stdout, stderr) {
                if (stdout !== null && stdout !== "") {
                    echo('stdout: ',stdout);  
                }
                if (error !== null) {
                    echo("Execute:",_7zCmd,"Failed!");
                    console.error( error.stack );
                }else{
                    echo("Execute:",_7zCmd,"Done!");
                    echo("Removed the rar file.")
                    fs.unlinkSync(rarfilePath);
                    waitFor.count();  
                }
        });
    }
}

function WaitForFinished(number){
    this.counter = number;
}

WaitForFinished.prototype.count = function () {
    if (this.counter !==0) this.counter --;
    if (this.counter == 0) {
        echo("------------------------------------------------------------------Starting renaming...")
        fs.readdir(BOOK_SAVE_PATH,function(err,files){files.forEach(function(file){renameBook(BOOK_SAVE_PATH,file)})})
    }
}


function doRealRename() {

    var numberOfRarFiles=0;
    fs.readdirSync(BOOK_SAVE_PATH).forEach(function(file){
        if (path.extname(file)===".rar"){
            var isbn = parseISBN(file);
            if (isbn !== undefined){
                numberOfRarFiles++;
            }
        }
    });
    //echo(numberOfRarFiles)
    
    var waitFor = new WaitForFinished(numberOfRarFiles);
    if (numberOfRarFiles === 0) waitFor.count();

    fs.readdir(BOOK_SAVE_PATH,function(err,files){files.forEach(function(file){
        if (path.extname(file)===".rar"){
            var isbn = parseISBN(file);
            if (isbn !== undefined){
                uncompressRarFile(file,isbn);
            }
        }
    })});

}

function main() {
    
    var argv = require('minimist')(process.argv.slice(2),{
        boolean:['h','v'],
        string:'o',
        alias: { v: 'version', h: 'help' },
        default: { o : 'rename' }
    });;

    Object.keys(argv).forEach(function(entry) {
        if ((entry == '_') || (entry == 'h') || (entry === 'help') || entry === 'version' || entry === 'v' || entry === 'o'){
            //echo("testing input",entry,"passed!");
        }else{
            //echo("testing input",entry,"faied!");
            errArgument();
            printusage();
            process.exit(0);
        }

    });

    if (argv._.length > 1) {
        errArgument();
        return printusage();
    }
    else if (argv._[0]){
        if (argv._[0] === 'clean') return doClean();
        if (argv._[0] === 'rename') return doRealRename();
        if (argv._[0] === 'help') return printusage();
        if (argv._[0] === 'version') return printVersion();
        errArgument();
        return printusage();
    }else {
        if (argv.v) return printVersion();
        if (argv.h) return printusage();
        if (argv.o === 'rename') {
            return doRealRename();
        }else if (argv.o === 'clean') {
            return doClean();
        }else {
            errArgument();
        }
    }
}

function printusage() {
    echo("Usage:","node",path.basename(process.argv[1]),"clean(-o clean)","|",
        "rename (-o rename)","|","version (-v|--version)","|","help (-h|--help)");
}
function printVersion() {
    echo("Version:","0.0.1");
}
function errArgument(){
    echo("Error Unkowned Aguramnt:",process.argv.slice(2))
}

function doClean() {
    echo("do clean...")
}

main();