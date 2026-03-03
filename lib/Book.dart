import 'dart:convert';
import 'package:flutter/material.dart';

class Book {
  final String titre;
  final String auteur;
  final String cover;
  final String token;
  final List<dynamic> listSommaires;

  Book({
    required this.titre,
    required this.auteur,
    required this.cover,
    required this.token,
    required this.listSommaires,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      titre: json['titre'],
      auteur: json['auteur'],
      cover: json['cover'],
      token: json['token'],
      listSommaires: json['listSommaires'],
    );
  }
}
