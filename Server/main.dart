import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'DataObject.dart';
import 'Collection.dart';
import 'AttributeContainer.dart';
import 'package:path/path.dart';

Map<String, dynamic> requestTypes = {
  "GET": true,
  "POST": true,
  "PUT": true,
  "HEAD": false,
  "DELETE": false,
  "PATCH": false,
  "OPTIONS": false
};
String ip = "localhost";
InternetAddress ipAddress;
int port = 4040;
List<Collection> dbs = new List<Collection>();

Future main() async {
  await startSequence();
  var server = await HttpServer.bind(
    ipAddress,
    port,
  );
  print(" * Server bound to $ip:${server.port}");

  await for (HttpRequest request in server) {
    String m = request.method;
    if (requestTypes[m]) {
      print("\n");
      handleRequest(request);
    } else {
      request.response.write("Error: Invalid request");
    }
  }
}

bool parseBool(String b) {
  if (b.toLowerCase() == "true") {
    return true;
  } else {
    return false;
  }
}

void handleRequest(HttpRequest r) {
  String m = r.method;
  try {
    switch (m) {
      case ("GET"):
        {
          handleGet(r);
        }
        break;
      case ("POST"):
        {
          handlePost(r);
        }
        break;
      case ("PUT"):
        {
          handlePost(r);
        }
        break;
      case ("HEAD"):
        {
          handlePost(r);
        }
        break;
      case ("DELETE"):
        {
          handlePost(r);
        }
        break;
      case ("PATCH"):
        {
          handlePost(r);
        }
        break;
      case ("OPTIONS"):
        {
          handlePost(r);
        }
        break;
    }
  } catch (e) {
    print("Exception in handleRequest: $e");
  }
}

void handleGet(HttpRequest r) {
  String end = "";
  String path = r.uri.path;

  if (path == "/query") {
    print("Object query from ${r.connectionInfo.remoteAddress}");
    String query = r.uri.queryParameters["q"];
    int id = int.parse(r.uri.queryParameters["id"]);
    print("Queried $query for object $id");
    if (dbs.any((Collection value) => value.name == query)) {
      Collection c = dbs.singleWhere((col) => col.name == query);
      DataObject data = c.dataList.singleWhere((d) => d.id == id);
      end = data.toString();
      print(end);
    }
  }

  if (path == "/query/attribute") {
    print("Attribute query from ${r.connectionInfo.remoteAddress}");
    String query = r.uri.queryParameters["q"];
    int id = int.parse(r.uri.queryParameters["id"]);
    String att = r.uri.queryParameters["a"];
    print("Queried $query for attribute $att of object $id");
    if (dbs.any((Collection value) => value.name == query)) {
      Collection c = dbs.singleWhere((col) => col.name == query);
      DataObject data = c.dataList.singleWhere((d) => d.id == id);
      AttributeContainer attribute =
          new AttributeContainer(att, data.data[att]);
      end = attribute.toJSON();
      print(end);
    }
  }

  var response = r.response;
  response.write(end);
  response.close();
}

void handlePost(HttpRequest r) {
  String end = "";
  String path = r.uri.path;

  if (path == "/add") {
    print("Empty object add request from ${r.connectionInfo.remoteAddress}");
    String add = r.uri.queryParameters["q"];
    int id = int.parse(r.uri.queryParameters["id"]);
    print("Requested to add object $id to $add");
    if (dbs.any((Collection value) => value.name == add)) {
      Collection c = dbs.singleWhere((col) => col.name == add);
      c.dataList.add(new DataObject.emptyMap(id));
      c.updateFile();
      print("Successfully added object $id to $add");
      var response = r.response;
      response.write("Successfully added object $id to $add");
      response.close();
    }
  } else if (path == "/add/obj") {
    print("Object add request from ${r.connectionInfo.remoteAddress}");
    String add = r.uri.queryParameters["q"];
    Future<String> content = utf8.decodeStream(r);
    if (dbs.any((Collection value) => value.name == add)) {
      Collection c = dbs.singleWhere((col) => col.name == add);
      content.then((result) {
        DataObject d = new DataObject.fromJsonString(result);
        print("Requested to add object ${d.id} to $add");
        c.dataList.add(d);
        c.updateFile();
        print("\nSuccessfully added this object to $add");
        var response = r.response;
        response.write("\nSuccessfully added this object to $add");
        response.close();
      });
    }
  } else if (path == "/add/attribute") {
    String newEnd = "";
    print("Attribute add request from ${r.connectionInfo.remoteAddress}");
    String add = r.uri.queryParameters["q"];
    int id = int.parse(r.uri.queryParameters["id"]);
    String att = r.uri.queryParameters["a"];
    Future<String> content = utf8.decodeStream(r);
    if (dbs.any((Collection value) => value.name == add)) {
      Collection c = dbs.singleWhere((col) => col.name == add);
      content.then((result) {
        AttributeContainer attribute =
            new AttributeContainer(att, json.decode(result)[att]);
        DataObject data = c.dataList.singleWhere((d) => d.id == id);
        print("Requested to add attribute ${attribute.key} to $id in $add");
        if (!data.data.containsKey(attribute.key)) {
          data.data[att] = attribute.value;
          c.updateFile();
          print("Successfully added $att to $id");
          var response = r.response;
          response.write("Successfully added $att to $id");
          response.close();
        } else {
          print("The attribute $att already exists in object $id");
          var response = r.response;
          response.write("The attribute $att already exists in object $id");
          response.close();
        }
      });
    }
  } else if (path == "/mod") {
    print("Object mod request from ${r.connectionInfo.remoteAddress}");
    String mod = r.uri.queryParameters["q"];
    int id = int.parse(r.uri.queryParameters["id"]);
    int newId = int.parse(r.uri.queryParameters["v"]);
    print("Requested to change $id to $newId in $mod");
    if (dbs.any((Collection value) => value.name == mod)) {
      Collection c = dbs.singleWhere((col) => col.name == mod);
      DataObject data = c.dataList.singleWhere((d) => d.id == id);
      data.id = newId;
      c.updateFile();
      print("Successfully modified $id to $newId");
      var response = r.response;
      response.write("Successfully modified $id to $newId");
      response.close();
    }
  } else if (path == "/mod/attribute") {
    String newEnd = "";
    print("Attribute mod request from ${r.connectionInfo.remoteAddress}");
    String mod = r.uri.queryParameters["q"];
    int id = int.parse(r.uri.queryParameters["id"]);
    String att = r.uri.queryParameters["a"];
    Future<String> content = utf8.decodeStream(r);
    if (dbs.any((Collection value) => value.name == mod)) {
      Collection c = dbs.singleWhere((col) => col.name == mod);
      content.then((result) {
        AttributeContainer attribute =
            new AttributeContainer(att, json.decode(result)[att]);
        print("Requested to modify attribute ${attribute.key} of $id in $mod");
        DataObject data = c.dataList.singleWhere((d) => d.id == id);

        if (data.data.containsKey(att)) {
          data.data[att] = attribute.value;
          c.updateFile();
          print("Successfully modified $att of $id in $mod");
          var response = r.response;
          response.write("Successfully modified $att of $id in $mod");
          response.close();
        } else {
          print("The attribute $att does not exist in object $id");
          var response = r.response;
          response.write("The attribute $att does not exist in object $id");
          response.close();
        }
      });
    }
    end = newEnd;
  } else {
    print("Error: Invalid request from ${r.connectionInfo.remoteAddress}");
    var response = r.response;
    response.write("Error: Invalid request");
    response.close();
  }
}

void handlePut(HttpRequest r) {}
void handleHead(HttpRequest r) {}
void handleDelete(HttpRequest r) {
  String m = r.method;
  r.response.write("this is a $m");
}

void handlePatch(HttpRequest r) {}
void handleOptions(HttpRequest r) {
  String m = r.method;
  r.response.write("this is a $m");
}

Future readConfig() async {
  File file = new File("config.json");
  String content;

  if (await file.exists()) {
    content = await file.readAsString();
  }
  var map = json.decode(content);
  ip = map["ip"];
  port = map["port"];
  requestTypes = map["Requests"];
}

void readDatabases() {
  Directory dir = new Directory("Databases");
  dir.list(recursive: false).listen((FileSystemEntity e) {
    print("--Loaded database: ${basename(e.path)}");
    String name = basename(e.path).split(".")[0];
    Collection c = new Collection(name);
    dbs.add(c);
  });
}

void createIP() {
  if (ip == "localhost" || ip == "127.0.0.1") {
    ipAddress = InternetAddress.loopbackIPv4;
  } else {
    ipAddress = new InternetAddress(ip);
  }
}

Future<void> startSequence() async {
  String version = await File("version.jserv").readAsString();
  print(" * Starting jServ v$version");
  print(" -----------------------");
  await readDatabases();
  print(" * Loading databases...");
  await readConfig();
  print(" * Loading config...");
  await createIP();
  print(" * Binding server...");
  print(" * Done!");
}