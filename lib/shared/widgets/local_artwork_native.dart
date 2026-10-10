// local_artwork_native.dart
import 'dart:io';
import 'package:flutter/material.dart';

ImageProvider localArtworkProvider(String path) => FileImage(File(path));
