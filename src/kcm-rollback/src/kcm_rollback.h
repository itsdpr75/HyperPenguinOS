#ifndef KCM_ROLLBACK_H
#define KCM_ROLLBACK_H

#include <KQuickAddons/ConfigModule>

class KcmRollback : public KQuickAddons::ConfigModule
{
    Q_OBJECT
    Q_PROPERTY(QVariantList snapshots READ snapshots NOTIFY snapshotsChanged)

public:
    explicit KcmRollback(QObject *parent = nullptr, const QVariantList &args = QVariantList());
    ~KcmRollback() override;

    QVariantList snapshots() const;

public Q_SLOTS:
    void load() override;
    void save() override;
    void defaults() override;
    void restoreSnapshot(int index);

Q_SIGNALS:
    void snapshotsChanged();
    void operationFinished(const QString &message, bool success);

private:
    QVariantList m_snapshots;
    void refreshSnapshots();
};

#endif // KCM_ROLLBACK_H
