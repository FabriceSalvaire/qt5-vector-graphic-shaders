/***************************************************************************************************
**
** Copyright (C) 2016 Fabrice Salvaire
** Contact: http://www.fabrice-salvaire.fr
**
** This file is part of qt5-vector-graphic-shaders
**
** This program is free software: you can redistribute it and/or modify
** it under the terms of the GNU General Public License as published by
** the Free Software Foundation, either version 3 of the License, or
** (at your option) any later version.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program.  If not, see <http://www.gnu.org/licenses/>.
**
***************************************************************************************************/

/**************************************************************************************************/

#include <cstdlib>

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QSurfaceFormat>
#include <QtDebug>
#include <QtQml>

/**************************************************************************************************/

// constexpr int EXIT_FAILURE = -1; // also defined in <cstdlib>

int
main(int argc, char *argv[])
{
  QSurfaceFormat surface_format;
  // surface_format.setSamples(4); // max is 8 ?
  QSurfaceFormat::setDefaultFormat(surface_format);

  // QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

  QGuiApplication application(argc, argv);

  QQmlApplicationEngine engine;
  // QQmlContext * root_context = engine.rootContext();

  engine.load(QUrl("qrc:/pages/main.qml"));
  if (engine.rootObjects().isEmpty())
    return EXIT_FAILURE;

  for (auto * obj : engine.rootObjects()) {
    QQuickWindow * window = qobject_cast<QQuickWindow *>(obj);
    if (window != NULL) {
      QSurfaceFormat format = window->format();
      qInfo() << "QQuickWindow found" << format;
    }
  }

  return application.exec();
}

/***************************************************************************************************
 *
 * End
 *
 **************************************************************************************************/
