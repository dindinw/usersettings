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
var echo = console.log;


/* Consts*/
var homedir = (process.platform === 'win32') ? process.env.HOMEPATH : process.env.HOME;
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
            var title = $('#btAsinTitle').children().get(0).prev.data.trim();
            title = title.replace(/:/g," -");
            var type  = $('#btAsinTitle').children().text().trim();
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
                date = (date.getMonth()<10) ? date.getFullYear()+"-0"+date.getMonth()
                                            : date.getFullYear()+"-"+date.getMonth();
            }
            
            newName.push(title);
            newName.push(date);
            newName.push(ASIN);
            newName = newName.join(", ")

            echo("Type     :",type)
            echo("Title    :",title);
            echo("New Name :",newName)

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

function ChangeNameJob(orginalFileName,fileExt){
    this.fileName=orginalFileName;
    this.fileExt=fileExt;
}
ChangeNameJob.prototype.changeName = function (newName){
    //check existed
    echo(this.fileName,"->",newName+this.fileExt);
    if (fs.existsSync(path.join(BOOK_SAVE_PATH,newName+this.fileExt))) {
        newName = newName+"_"+Date.now();;
        echo("WARNING:","File exists!","->",newName+this.fileExt);

    }
    fs.renameSync(path.join(BOOK_SAVE_PATH,this.fileName),
        path.join(BOOK_SAVE_PATH,newName+this.fileExt));
}

function renameBookNames(err,files){
    for (var i = 0; i<files.length ; i++){
        if (fs.statSync(path.join(BOOK_SAVE_PATH,files[i])).isDirectory())
            continue; //not handle subdirectory.
        var fileName=files[i];
        var fileExt=path.extname(fileName);
        var fileBaseName=path.basename(fileName,fileExt);
        
        var job = new ChangeNameJob(fileName,fileExt);

        if (ISBN10_REGXP.test(fileBaseName)) {         //Goolge for ISDN
            var isbn=ISBN10_REGXP.exec(fileBaseName)[0]
            //echo("isbn",isbn);
            requestByAmazon(job,isbn);
        } else if (ASIN_REGXP.test(fileBaseName)) {  //Amzon for ASIN
            var asin=ASIN_REGXP.exec(fileBaseName)[0]
            //echo("asin",asin);
            requestByAmazon(job,asin); 
        }else{
            echo("WARNING :","Can't parse a isdn or asin from given name : [",fileName,"]");
            continue;
        }

    }

}

fs.readdir(BOOK_SAVE_PATH,renameBookNames);