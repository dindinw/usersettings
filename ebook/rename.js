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
var os = require('os');

/* Consts*/
var homedir = (process.platform === 'win32') ? process.env.USERPROFILE : process.env.HOME;
//echo (homedir)
//var BOOK_SAVE_PATH="C:\\Users\\yidwu\\Downloads\\_Un"
var BOOK_SAVE_PATH=path.join(homedir,"Downloads","_Un"); //cross-platform path
var RENAME_ANSWER_DEFAULT_NAME = 'rename-answerfile.txt';
var RENAME_ANSWER_DEFAULT_BASENAME = path.basename(RENAME_ANSWER_DEFAULT_NAME,path.extname(RENAME_ANSWER_DEFAULT_NAME));
var RENAME_ANSWER_FILE = path.join(BOOK_SAVE_PATH,RENAME_ANSWER_DEFAULT_NAME);
/* Regxp */
var MONTH_REGXP="(January|February|March|April|May|June|July|August|September|October|November|December).*"
var MONTH_ABBREV_REGXP="(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)"
var ISBN10_REGXP="\\d{9}[\\d|X]"
var ISBN13_REGXP="(978|979)(?:-|)\\d{9}[\\d|X]"
var EDTION_REGXP="\\d{1}"
var ASIN_REGXP="[A-Z0-9]{10}"




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
            
            title = title.replace(/:/g," -");
            title = title.replace(/\//g,"&");
            title = title.replace(/\?/g,"");

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
            //echo(body)
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
            title = title.replace(/\//g,"&");
            title = title.replace(/\?/g,"");
            
            var date
            var pubdate = $('#pubdate').val();

            // get pubdate from buying dev
            if (pubdate === undefined) {
                $('div[class=buying]').find('span[style="font-weight: bold;"]').each(function() {
                    echo("----------------")
                    var text = $(this).text().trim();
                    echo(text);
                    if (new RegExp(MONTH_REGXP).test(text)){
                        echo("Pub Date :",text);
                        pubdate = Date.parse(text);
                    }else if (new RegExp(ISBN13_REGXP).test(text)){
                        echo("ISDN_13  :",text);
                    }
                    else if(new RegExp(ISBN10_REGXP).test(text)){
                        echo("ISDN_10  :",text);
                    }else if(new RegExp('^'+EDTION_REGXP+'$').test(text)){
                        echo("Edtion   :",text);
                    }
                    
                });
            }
            // try to get pubdate from detail-bullets div
            if (pubdate === undefined) {
                $('div[id=detail-bullets]').find('li').each(function() {
                    //echo("in detail-bullets")
                    var text= $(this).text().trim();
                    //echo(text);
                    if (new RegExp("Publisher:.*").test(text)){
                        echo("Publisher:",text);
                        text = text.replace(/.*\(/,"");
                        text = text.replace(/\)/,"");
                        text = text.trim();
                        //echo(text)
                        if (new RegExp(MONTH_REGXP).test(text)){
                            echo("Pub Date :",text);
                            pubdate = Date.parse(text);
                        }
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
        this.pubdate = this.pubdate instanceof Date ? this.pubdate : new Date(this.pubdate);
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
ChangeNameJob.prototype.writeFile = function (keywords,isbn,bookname,pubdate){

    var date = new Date(Date.parse(pubdate));
    var month= date.getMonth()+1
    date = (month<10) ? date.getFullYear()+"-0"+month:date.getFullYear()+"-"+month;
    var newname = bookname +", "+date+", "+isbn;

    echo("Save search result :",this.fileName,"|",isbn,"|",newname,"|",pubdate);
    fs.appendFile(path.join(RENAME_ANSWER_FILE), os.EOL+this.fileName
        +" | "+keywords
        +" | "+isbn+" | "+newname+ " | "+pubdate+os.EOL, function (err) {
        if (err != null) echo(err);
    });
}

function parseISBN(name,matchFromStart){
    //echo("parseISBN",name)
    var isbn
    if (matchFromStart === undefined) matchFromStart = true;
    //echo("matchFromStart=",matchFromStart)
    var isbn13 = matchFromStart ? new RegExp('^'+ISBN13_REGXP) : new RegExp(ISBN13_REGXP)  ;
    var isbn10 = matchFromStart ? new RegExp('^'+ISBN10_REGXP) : new RegExp(ISBN10_REGXP) ;
    var asin = matchFromStart ? new RegExp('^'+ASIN_REGXP) : new RegExp(ASIN_REGXP);

    if (isbn13.test(name)) {    
        isbn = isbn13.exec(name)[0];
        //echo("isbn13",isbn);
    }
    else if (isbn10.test(name)){
        isbn = isbn10.exec(name)[0];
        //echo("isbn10",isbn);
    }
    else if (asin.test(name)) { 
        isbn=asin.exec(name)[0];
        //echo("asin",isbn);
    }
    if (isbn === undefined){
        echo("WARNING :","Can't parse a isdn or asin from '",name,"'");
    }
    return isbn;
}

function searchISBN(name,callback){
    var searchname = path.basename(name,path.extname(name));
    searchname = searchname.replace(/[:._\/\(\),]/g," ");
    echo(searchname);
    searchname = searchname.replace(/eBook-DDU/g,"");
    searchname = searchname.replace(/(19|20)\d{2}/g,"") //year
    echo(searchname);
    searchname = searchname.replace(new RegExp(MONTH_ABBREV_REGXP+'(\\s+\\d{1,2}|\\s+|\\.)'),""); //month
    echo(searchname);
    searchname = searchname.replace(/(^\s+|\s+$)/g,"") //trim
    echo(searchname);
    searchname = searchname.replace(/\s{2,}/g," ") //extra whitesapces
    echo(searchname);

    searchname = searchname.replace(/\s\w+\sEdition\s\w+/g,"");
    echo(searchname);

    searchname = searchname.replace(/[\s+]/g,'+');
    echo(searchname);
    echo("Keywords:",searchname);
    var isbn
    var reqBody = {
        method:'GET',
        uri:"http://www.amazon.com/s/ref=nb_sb_noss?url=search-alias%3Daps&field-keywords="+searchname
    };
    request(reqBody,function(err,rep,body){
        if(rep.statusCode == 200){
            echo('-----------------------------------------------------------');
            echo(reqBody.uri);
            var $ = cheerio.load(body);
            var isbnStr = $('div[id=result_0]').attr('name');
            var bookname = $('div[id=result_0]').find('span').first().text();
            bookname = bookname.replace(/:/g," -");
            bookname = bookname.replace(/\//g,"&")

            var length = $('div[id=result_0]').find('span').length

            var authorAndDate = $('div[id=result_0]').find('span').eq(1).text();
            echo ("authorAndDate:",authorAndDate);
            var authorAndDate_RegExp = new RegExp(MONTH_ABBREV_REGXP+'(\\s+\\d{1,2}\,\\s+\\d{4}|\\s+\\d{4})');
            var date 
            if (authorAndDate_RegExp.test(authorAndDate))
                date = authorAndDate_RegExp.exec(authorAndDate)[0];
            echo ("pubdate:",date);
            //echo (Date.parse(date));
            //var pubdate = new Date(Date.parse(date));
            //echo(pubdate);
            echo("The result 0 isbn :",isbnStr);
            echo("The result 0 name :",bookname);
            isbn = parseISBN(isbnStr,true);
            //echo("After parse test:",isbn);

            if (isbn === undefined){
                echo("WARNING :","Fail to find a isdn or asin by '",name,"'");
            }else{
                var noresult = $('h1[id=noResultsTitle]').text();
                if (noresult) {
                    echo(noresult);
                }
                callback(searchname,isbn,bookname,date);
            }
        }
        else{
            echo('error :',rep.statusCode);
            echo(body);

        }
    });

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

function uncompressRarFile(rarfile,isbn,waitFor){
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


function doDefaultRename() {

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
                uncompressRarFile(file,isbn,waitFor);
            }
        }
    })});

}

function doClean(search) {
    //echo("do clean...")
    if (search){ //clean answer file frist before do search.
        var answerfile = path.join(RENAME_ANSWER_FILE);
        if (fs.existsSync(answerfile)) {
            var ext = path.extname(RENAME_ANSWER_FILE);
            var basename = path.basename(RENAME_ANSWER_FILE,ext);
            RENAME_ANSWER_FILE = path.join(BOOK_SAVE_PATH,basename+"_"+Date.now()+ext);
        }
        echo("ANSWERFILE:",RENAME_ANSWER_FILE);
    }
    fs.readdir(BOOK_SAVE_PATH,function(err,files){files.filter(function(file){
        //echo(file,RENAME_ANSWER_DEFAULT_BASENAME);
        if (file.indexOf(RENAME_ANSWER_DEFAULT_BASENAME) === 0 ) return false; //don't handle the answer file
        if (file == path.basename(RENAME_ANSWER_FILE)) return false;
        return true; 
    }).forEach(function(file){
            
        var isbn = parseISBN(file,false);
        var baseName=path.basename(file,path.extname(file));
        if (isbn !== undefined && baseName != isbn){
            //echo(file,"->",isbn);
            var job = new ChangeNameJob(BOOK_SAVE_PATH,file,path.extname(file));
            job.changeName(isbn);
        }
        if (isbn === undefined){
            if(search){
                echo("Try to search the name keyword to get isdn")
                searchISBN(file,function(keywords,isbn,bookname,pubdate){
                    var job = new ChangeNameJob(BOOK_SAVE_PATH,file,path.extname(file));
                    job.writeFile(keywords,isbn,bookname,pubdate);
                });
            }
        }
        
    })});
}

function renameByAnswerfile(answerfile){
    echo(renameByAnswerfile,answerfile);
    fs.readFile(answerfile,function(err,data){
        //echo(data.toString());
        var lines = data.toString().split(os.EOL);
        lines.filter(function(line){
            return !/^(\s+|)$/.test(line);
        }).filter(function(line){
            var items = line.split('|');
            var filename = items[0].trim();
            var filepath = path.join(BOOK_SAVE_PATH,filename);
            if (fs.existsSync(filepath)) return true;
            else 
                echo("WARING:",filepath,"not exists");
        })
        .forEach(function(line){
            echo(line);
            var items = line.split('|');
            var oldName = items[0].trim();
            var searchkeywords = items[1].trim();
            var isbn = items[2].trim();
            var newName =  items[3].trim();
            var pubdate = items[4].trim();
            var job = new ChangeNameJob(BOOK_SAVE_PATH,oldName,path.extname(oldName));
            job.pubdate=Date.parse(pubdate);
            job.changeName(newName);
        });
    });
}

function recoveryByAnswerfile(answerfile){
    echo(renameByAnswerfile,answerfile);
    fs.readFile(answerfile,function(err,data){
        //echo(data.toString());
        var lines = data.toString().split(os.EOL);
        lines.filter(function(line){
            return !/^(\s+|)$/.test(line);
        }).forEach(function(line){
            echo(line);
            var items = line.split('|');
            var oldName = items[0].trim();
            var searchkeywords = items[1].trim();
            var isbn = items[2].trim();
            var newName =  items[3].trim();
            var job = new ChangeNameJob(BOOK_SAVE_PATH,newName+path.extname(oldName),path.extname(oldName));
            job.changeName(path.basename(oldName,path.extname(oldName)));
        });
    });
}


function main() {
    
    var argv = require('minimist')(process.argv.slice(2),{
        string:['d'],
        alias: { v: 'version', h: 'help', d: 'directory', s:'search' }, 
    });;

    if (argv._.length == 0 && Object.keys(argv).length == 1){ //without any opts
        return doDefaultRename(); //do rename by default
    }
    Object.keys(argv).forEach(function(entry) {
        if (entry === '_' || entry === 'h' || entry === 'help' 
            || entry === 'v' || entry === 'version'
            || entry === 's' || entry === 'search'
            || entry === 'd' || entry === 'directory'
            || entry === 'answerfile' || entry === 'withanswerfile' ){
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
    if (argv.v) return printVersion();
    if (argv.h) return printusage();
    if (argv.d){
        try{
            var rootDir = path.join(argv.d);
            fs.readdirSync(rootDir);
            BOOK_SAVE_PATH=rootDir;
            //also need to change answer file path.
            RENAME_ANSWER_FILE = path.join(BOOK_SAVE_PATH,RENAME_ANSWER_DEFAULT_NAME); 
        }catch(e){
            errArgument();
            echo(e.message.split(",")[1]);
            process.exit(0);
        }
    }
    if (argv.answerfile) {
        if (!(typeof argv.answerfile === 'boolean')){
            var answerfile //= path.join(argv.answerfile);
            if (fs.existsSync(answerfile)) {
                RENAME_ANSWER_FILE = answerfile;
            }else{
                answerfile = path.join(BOOK_SAVE_PATH,argv.answerfile);
                if (fs.existsSync(answerfile)) {
                    RENAME_ANSWER_FILE = answerfile;
                }else{
                    echo("Error:",answerfile,"not found!");
                    process.exit(0);
                }
            }
        }else{
            echo("Error:","--answerfile need provide a file path.")
            process.exit(0);
        }        
    }
    if (argv._[0]){
        if (argv._[0] === 'clean') {
            return doClean(argv.s);
        }
        if (argv._[0] === 'rename') {
            if (argv.withanswerfile||argv.answerfile){
                return renameByAnswerfile(RENAME_ANSWER_FILE); 
            }
            else{
                return doDefaultRename();
            }
        }
        if (argv._[0] === 'recovery') {
            return recoveryByAnswerfile(RENAME_ANSWER_FILE);
        }
        if (argv._[0] === 'help') return printusage();
        if (argv._[0] === 'version') return printVersion();
        errArgument();
        return printusage();
    }else {
        errArgument();
    }
}

function printusage() {
    echo("Uasge:","node",path.basename(process.argv[1]),"rename [-d|--drectory <dir>] [--withanswerfile] [--answerfile <filepath>]");
    echo("      ","node",path.basename(process.argv[1]),"clean [-d|--directory <dir>] [-s|--search] [--answerfile <filepath>]");
    echo("      ","node",path.basename(process.argv[1]),"recovery [-d|--drectory <dir>] [--answerfile <filepath>]");    
    echo("      ","node",path.basename(process.argv[1]),"version (-v|--version)");
    echo("      ","node",path.basename(process.argv[1]),"help (-h|--help)");
}
function printVersion() {
    echo(path.basename(process.argv[1]),"Version:","0.0.1");
}
function errArgument(){
    echo("Error or Unknown Argument:",process.argv.slice(2))
}

main();
