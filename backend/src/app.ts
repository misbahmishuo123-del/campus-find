import express, { Application } from "express";
import cors from "cors";
import routes from "./routes";
import { notFoundHandler, errorHandler } from "./middleware/errorHandler";

export function createApp(): Application {
  const app = express();

  app.use(cors());
  app.use(express.json({ limit: "1mb" }));
  app.use(express.urlencoded({ extended: true }));

  app.get("/", (_req, res) => {
    res.json({
      success: true,
      message: "CampusFind API",
      docs: "/api/health",
    });
  });

  app.use("/api", routes);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
