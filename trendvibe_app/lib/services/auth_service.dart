import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/user.dart';


class AuthService {


  Future<User?> login(
      String email,
      String password
      ) async {


    final response = await http.post(
      Uri.parse("${Constants.baseUrl}/api/auth/login"),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode({

        "email": email,
        "password": password

      }),
    );


    if(response.statusCode == 200){

      final data = jsonDecode(response.body);

      return User.fromJson(data);

    }

    return null;
  }



  Future<bool> register(
      String nombre,
      String email,
      String password
      ) async {


    final response = await http.post(
      Uri.parse("${Constants.baseUrl}/api/auth/register"),
      headers:{
        "Content-Type":"application/json"
      },
      body:jsonEncode({

        "nombre":nombre,
        "email":email,
        "password":password

      }),
    );


    return response.statusCode == 201;
  }

}