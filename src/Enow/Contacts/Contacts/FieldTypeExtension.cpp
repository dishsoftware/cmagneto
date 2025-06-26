#include "FieldTypeExtension.hpp"

#include <boost/bimap.hpp>
#include <QtGlobal>

#include <stdexcept>


namespace Enow::Contacts::Contacts::FieldType {
    const boost::bimap<Enum, QString>& allValues() {
        static const boost::bimap<Enum, QString>* values = nullptr;
        if (!values) {
            const auto newValues = new boost::bimap<Enum, QString>();
            newValues->insert({Enum::kString, "String"});
            newValues->insert({Enum::kPhoneNumber, "PhoneNumber"});
            newValues->insert({Enum::kEMailAddress, "EMailAddress"});
            newValues->insert({Enum::kLocation, "Location"});
            newValues->insert({Enum::kGraphics, "Graphics"});
            values = newValues;
        }
        return *values;
    }

    const std::set<Enum>& allEnums() {
        static const std::set<Enum>* enums;
        if (!enums) {
            const auto newEnums = new std::set<Enum>();
            for (const auto& [enumValue, _] : allValues().left)
                newEnums->insert(enumValue);

            enums = newEnums;
        }
        return *enums;
    }

    const std::set<QString>& allStrings() {
        static const std::set<QString>* strings;
        if (!strings) {
            const auto newStrings = new std::set<QString>();
            for (const auto& [_, str] : allValues().left)
                newStrings->insert(str);

            strings = newStrings;
        }
        return *strings;
    }

    const QString& toString(const Enum iEnum) {
        const auto it = allValues().left.find(iEnum);
        Q_ASSERT_X(it != allValues().left.end(), "Enow::Contacts::Contacts::FieldType::toString", "Reconcile Enum and allValues() implementation!");
        return it->second;
    }

    Enum toEnum(const QString& iStr) {
        const auto it = allValues().right.find(iStr);
        if (it == allValues().right.end())
            throw std::invalid_argument("Enow::Contacts::Contacts::FieldType::toEnum: invalid string representation \"" + iStr.toStdString() + "\"");

        return it->second;
    }
} // namespace Enow::Contacts::Contacts::FieldType