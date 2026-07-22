import 'package:flutter/material.dart';

// رابط الـ API الخاص بـ Google Apps Script
const String webAppUrl = "https://script.google.com/macros/s/AKfycbyCnd0DcFXHxHxJY9kkLYY8HFM282urHGizg9nhenV-rdq623liL0v7YdBDJjkeOpatGx/exec";

void main() {
  runApp(const RestaurantApp());
}

class RestaurantApp extends StatelessWidget {
  const RestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إدارة الصالة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            'تطبيق إدارة صالة المطعم',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
