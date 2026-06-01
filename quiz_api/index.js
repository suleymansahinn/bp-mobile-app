const express = require("express");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

// Yazım Kuralları Quiz API
app.get("/quiz", (req, res) => {
  const questions = [
    {
      type: "fill",
      question:
        "Asagidaki cumlede bos birakilan yere uygun kelimeyi yaz:\n\nBugun hava ____ guzel.",
      answer: "cok",
    },
    {
      type: "tf",
      question:
        "'Bir sey' kelimesinin dogru yazimi ayri sekildedir.",
      answer: true,
    },
    {
      type: "fill",
      question:
        "Cumledeki yazim yanlisini duzeltiniz:\n\nBirsey anlamadim.",
      answer: "bir sey",
    },
    {
      type: "tf",
      question:
        "'Her sey' ifadesi bitisik yazilir.",
      answer: false,
    },
  ];

  res.json(questions);
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`API calisiyor: http://localhost:${PORT}/quiz`);
});
