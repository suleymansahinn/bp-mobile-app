import 'package:flutter/material.dart';

class QuestionHighlighter {
  static Widget highlightBlank(String question) {
    // "__" boşluk yerine alt çizgi ekleyebiliriz
    final highlighted = question.replaceAll('____', '_____');
    return Text(highlighted);
  }
}