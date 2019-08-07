/* === This file is part of Calamares - <https://github.com/calamares> ===
 *
 *   Copyright 2019, Adriaan de Groot <groot@kde.org>
 *
 *   Calamares is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   Calamares is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with Calamares. If not, see <http://www.gnu.org/licenses/>.
 */

#include "FreeBSDJob.h"

#include "CalamaresVersion.h"
#include "JobQueue.h"
#include "GlobalStorage.h"
#include "utils/Logger.h"

#include <QProcess>
#include <QDateTime>
#include <QThread>


FreeBSDJob::FreeBSDJob( QObject* parent )
    : Calamares::CppJob( parent )
{
}


FreeBSDJob::~FreeBSDJob()
{
}


QString
FreeBSDJob::prettyName() const
{
    return tr( "FreeBSD Installation Job" );
}

Calamares::JobResult
FreeBSDJob::exec()
{
    emit progress( 0.1 );
    cDebug() << "[FREEBSD]";

    Calamares::JobQueue::instance()->globalStorage()->debugDump();
    emit progress( 0.5 );

    QThread::sleep( 3 );
    emit progress( 1.0 );

    return Calamares::JobResult::ok();
}


void
FreeBSDJob::setConfigurationMap( const QVariantMap& configurationMap )
{
    // TODO: actually fetch something from that configuration
    m_configurationMap = configurationMap;
}

CALAMARES_PLUGIN_FACTORY_DEFINITION( FreeBSDJobFactory, registerPlugin<FreeBSDJob>(); )
