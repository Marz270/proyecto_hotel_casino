const express = require("express");
const cors = require("cors");
const morgan = require("morgan");
require("dotenv").config();
const indexRoutes = require("./routes/index.routes");
const valetKeyRoutes = require("./routes/valetKey.routes");
const roomsRoutes = require("./routes/rooms.routes");
const { initSoapServer } = require("./soap/bookingService");
const app = express();

app.use(cors());
app.use(morgan("dev"));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    message: "Something went wrong!",
    error: err.message,
  });
});

// Routes
app.use("/", indexRoutes, valetKeyRoutes, roomsRoutes);

// Inicializar servidor SOAP
initSoapServer(app);

const PORT = process.env.PORT;

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`REST API available at http://localhost:${PORT}`);
  console.log(
    `SOAP Service available at http://localhost:${PORT}/soap/booking?wsdl`
  );
});
