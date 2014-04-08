/*
 * A node.js script to rename a ebook file by given isdn.

 * Google Book API:
 * https://www.googleapis.com/books/v1/volumes?q=isbn:<your_isbn_here>
 * https://www.googleapis.com/books/v1/volumes?q=isbn:1617290572
 */
'use strict'; //strict mode 
var request = require('request');
var fs = require('fs');
var path = require('path');
var cheerio = require('cheerio');
var echo = console.log;

/* Consts*/
var BOOK_SAVE_PATH="C:\\Users\\yidwu\\Downloads\\_Un"
var ISBN_REGXP=/\d{9}[\d|X]/
var ASIN_REGXP=/[A-Z0-9]{10}/

function requestByISBN(bookNameCallback,isbn){
    var reqBody = {
        method:'GET',
        uri: 'https://www.googleapis.com/books/v1/volumes?q=isbn:' + isbn
    };
    request(reqBody,function(err,rep,body){
        if(rep.statusCode == 200){
            
            var jsObject = JSON.parse(body);
            echo("------------------------------------------------------------")
            echo(reqBody.uri)
            
            var newName = "";
            if (jsObject.items == undefined) {
                echo ('Error :'+isbn+", no result found!")
                return
            }
            var title=jsObject.items[0].volumeInfo.title;
            newName+=title+", "
            
            var subtitle=jsObject.items[0].volumeInfo.subtitle
            if (subtitle != undefined) newName += subtitle+", ";
            
            var date=jsObject.items[0].volumeInfo.publishedDate;
            newName += date.substr(0,7)+", ";
            
            echo("Title    :",title);
            echo("SubTitle :",subtitle)
            echo("Date     :" ,date);
            
            newName += isbn
            bookNameCallback(newName);
        }else{
            echo('error :',rep.statusCode);
            echo(body);

        } 
    });
}

//requestByIsbn(doBookName,'1617290572');   

function requestByASIN(bookNameCallback,ASIN){
    var reqBody = {
        method:'GET',
        uri: 'http://www.amazon.com/dp/' + ASIN
    };
    request(reqBody,function(err,rep,body){
        if(rep.statusCode == 200){
            echo("------------------------------------------------------------")
            echo(reqBody.uri)
            var $ = cheerio.load(body,{ xmlMode: true});
            echo($('span[id=btAsinTitle]').text());
            echo("foo",$('div[id=bookmetadata]').html());
            echo("bar",$('span[id=pubdatelabel]').text());
            echo("bar",$('span[id=pubdatevalue]'));
            var newName = "";
            var title;
            var subtitle;
            var date;
            
            echo("Title    :",title);
            echo("SubTitle :",subtitle)
            echo("Date     :" ,date);
            
            newName += ASIN
            echo("New Name :",newName)
            //bookNameCallback(newName);
        }else{
            echo('error :',rep.statusCode);
            echo(body);

        } 
    });
}

function renameBookNames(err,files){
    
    for (var i = 0; i<files.length ; i++){
        
        var fileName=files[i];
        var fileExt=path.extname(fileName);
        var fileBaseName=path.basename(fileName,fileExt);
        
        var doBookName = function changeName(newName){
            echo(changeName.fileName,"->",newName+changeName.fileExt)
            fs.renameSync(BOOK_SAVE_PATH+"\\"+changeName.fileName,
                BOOK_SAVE_PATH+"\\"+newName+changeName.fileExt);
        }
        doBookName.fileName=fileName
        doBookName.fileExt=fileExt

        if (ISBN_REGXP.test(fileBaseName)) {         //ISDN
            var isbn=ISBN_REGXP.exec(fileBaseName)[0]
            requestByISBN(doBookName,isbn); 
        } else if (ASIN_REGXP.test(fileBaseName)) {  //ASIN
            var asin=ASIN_REGXP.exec(fileBaseName)[0]
            requestByASIN(doBookName,asin); 
        }else{
            echo("ERROR :","Can't parse a isdn or asin from given name ",fileName);
            continue;
        }

    }

}

fs.readdir(BOOK_SAVE_PATH,renameBookNames);