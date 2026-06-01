const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * GET /getQuizQuestions
 * Flutter quiz ekranı bu endpoint'i çağırır
 */
exports.getQuizQuestions = functions.https.onRequest((req, res) => {
  // CORS (Flutter için şart)
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  const questions = [
    {
      type: "fill",
      question: "Asagidaki cumlede boslugu doldur:\n\nBu gun hava ____.",
      answer: "guzel",
    },
    {
      type: "tf",
      question: "‘Bir sey’ kelimesi bitisik yazilir.",
      answer: false,
    },
    {
      type: "fill",
      question:
        "Asagidaki cumlede bos birakilan yere uygun kelimeyi yaz:\n\nHer sey ____ guzel olacak.",
      answer: "cok",
    },
  ];

  return res.status(200).json(questions);
});
