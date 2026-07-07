#include "kcm_rollback.h"
#include <QProcess>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QDebug>

KcmRollback::KcmRollback(QObject *parent, const QVariantList &args)
    : KQuickAddons::ConfigModule(parent, args)
{
    refreshSnapshots();
}

KcmRollback::~KcmRollback() = default;

QVariantList KcmRollback::snapshots() const
{
    return m_snapshots;
}

void KcmRollback::load()
{
    refreshSnapshots();
}

void KcmRollback::save()
{
    // No persistent config to save for this KCM
}

void KcmRollback::defaults()
{
    // No defaults to apply
}

void KcmRollback::refreshSnapshots()
{
    m_snapshots.clear();

    QProcess process;
    process.start("btrfs", {"subvolume", "list", "-s", "/"});
    process.waitForFinished();

    if (process.exitCode() != 0) {
        qWarning() << "Failed to list BTRFS snapshots";
        Q_EMIT snapshotsChanged();
        return;
    }

    QString output = QString::fromUtf8(process.readAllStandardOutput());
    QStringList lines = output.split('\n', Qt::SkipEmptyParts);

    for (const QString &line : lines) {
        QStringList parts = line.split(' ', Qt::SkipEmptyParts);
        if (parts.size() >= 9) {
            QVariantMap snapshot;
            snapshot["id"] = parts[1];
            snapshot["gen"] = parts[3];
            snapshot["topLevel"] = parts[5];
            snapshot["path"] = parts[8];
            snapshot["name"] = parts[8].section('/', -1);
            m_snapshots.append(snapshot);
        }
    }

    Q_EMIT snapshotsChanged();
}

void KcmRollback::restoreSnapshot(int index)
{
    if (index < 0 || index >= m_snapshots.size()) {
        Q_EMIT operationFinished("Índice de snapshot inválido", false);
        return;
    }

    QVariantMap snap = m_snapshots[index].toMap();
    QString path = snap["path"].toString();
    QString snapId = snap["id"].toString();

    QProcess process;
    process.start("btrfs", {"subvolume", "snapshot", path, "/@rootfs"});
    process.waitForFinished();

    if (process.exitCode() == 0) {
        Q_EMIT operationFinished(
            QString("Snapshot %1 restaurado. Reinicia para aplicar cambios.").arg(snapId),
            true
        );
    } else {
        Q_EMIT operationFinished(
            QString("Error al restaurar snapshot %1").arg(snapId),
            false
        );
    }
}
