<?php

/**
 * @param string $rootPath
 *
 * @return mysqli|null
 */
function getMagento1DatabaseConnection($rootPath)
{
    $scriptPath = dirname(__FILE__);

    $databaseHost =
        shell_exec(sprintf('php %s/read_config_value.php %s global/resources/default_setup/connection/host localhost false',
            $scriptPath, $rootPath));
    $databasePort =
        (int)shell_exec(sprintf('php %s/read_config_value.php %s global/resources/default_setup/connection/port 3306 false',
            $scriptPath, $rootPath));
    $databaseUser =
        shell_exec(sprintf('php %s/read_config_value.php %s global/resources/default_setup/connection/username none false',
            $scriptPath, $rootPath));
    $databasePassword =
        shell_exec(sprintf('php %s/read_config_value.php %s global/resources/default_setup/connection/password none false',
            $scriptPath, $rootPath));
    $databaseName =
        shell_exec(sprintf('php %s/read_config_value.php %s global/resources/default_setup/connection/dbname none false',
            $scriptPath, $rootPath));

    if (empty($databaseHost) || empty($databasePort) || empty($databaseUser) || empty($databasePassword) ||
        empty($databaseName)) {
        return null;
    }

    $connection = new mysqli($databaseHost, $databaseUser, $databasePassword, $databaseName, $databasePort);

    if ($connection->connect_error) {
        die('Connect Error (' . $connection->connect_errno . ') ' . $connection->connect_error);
    }

    return $connection;
}

/**
 * @param string $rootPath
 * @param string $magento1ConfigFile
 * @param string $configValue
 * @param string $defaultValue
 * @param bool   $checkDatabase
 *
 * @return array
 */
function getMagento1ConfigValue($rootPath, $magento1ConfigFile, $configValue, $defaultValue, $checkDatabase = true)
{
    $result = [];

    if ($checkDatabase) {
        $databaseConnection = getMagento1DatabaseConnection($rootPath);

        if ($databaseConnection) {
            $databaseConfigValue = trim($configValue);
            $databaseConfigValue = trim($databaseConfigValue, '/');
            $databaseConfigValue = preg_replace('/^default\/(.*)/', '$1', $databaseConfigValue);
            $databaseConfigValue = preg_replace('/^global\/(.*)/', '$1', $databaseConfigValue);
            $databaseConfigValue = preg_replace('/\*/', '%', $databaseConfigValue);

            while (substr_count($databaseConfigValue, '/') < 2) {
                $databaseConfigValue = sprintf('%s/%%', $databaseConfigValue);
            }

            $tablePrefix =
                getMagento1ConfigValue($rootPath, $magento1ConfigFile, 'global/resources/db/table_prefix', '', false);

            if (count($tablePrefix) > 0) {
                $tablePrefix = reset($tablePrefix);
            }

            $configTableName = sprintf('%score_config_data', empty($tablePrefix) ? '' : $tablePrefix);

            /** @noinspection SqlResolve */
            $resultValues =
                $databaseConnection->query("SELECT `value` FROM `$configTableName` WHERE PATH like '$databaseConfigValue'");

            if ($resultValues) {
                $row = $resultValues->fetch_assoc();
                do {
                    if (is_array($row) && array_key_exists('value', $row)) {
                        $result[] = $row[ 'value' ];
                    }
                    $row = $resultValues->fetch_assoc();
                } while ($row);
                $resultValues->close();
            }
        }
    }

    $configFileXml = simplexml_load_file($magento1ConfigFile);

    if (substr_count($configValue, '/') == 2) {
        $defaultConfigValue = sprintf('default/%s', $configValue);
        $configValueNodes = $configFileXml->xpath(sprintf('/config/%s', $defaultConfigValue));
        if (is_array($configValueNodes) && count($configValueNodes) > 0) {
            foreach ($configValueNodes as $configValueNode) {
                if ($configValueNode instanceof SimpleXMLElement) {
                    $result[] = (string)$configValueNode;
                }
            }
        }
    }

    $configValueNodes = $configFileXml->xpath(sprintf('/config/%s', $configValue));
    if (is_array($configValueNodes) && count($configValueNodes) > 0) {
        foreach ($configValueNodes as $configValueNode) {
            if ($configValueNode instanceof SimpleXMLElement) {
                $result[] = (string)$configValueNode;
            }
        }
    }

    return empty($result) ? [$defaultValue] : array_unique($result);
}

/**
 * @param string $rootPath
 *
 * @return mysqli|null
 */
function getMagento2DatabaseConnection($rootPath)
{
    $scriptPath = dirname(__FILE__);

    $databaseHost =
        shell_exec(sprintf('php %s/read_config_value.php %s db/connection/default/host localhost false', $scriptPath,
            $rootPath));
    $databasePort =
        (int)shell_exec(sprintf('php %s/read_config_value.php %s db/connection/default/port 3306 false', $scriptPath,
            $rootPath));
    $databaseUser =
        shell_exec(sprintf('php %s/read_config_value.php %s db/connection/default/username none false', $scriptPath,
            $rootPath));
    $databasePassword =
        shell_exec(sprintf('php %s/read_config_value.php %s db/connection/default/password none false', $scriptPath,
            $rootPath));
    $databaseName =
        shell_exec(sprintf('php %s/read_config_value.php %s db/connection/default/dbname none false', $scriptPath,
            $rootPath));

    if (empty($databaseHost) || empty($databasePort) || empty($databaseUser) || empty($databasePassword) ||
        empty($databaseName)) {
        return null;
    }

    $connection = new mysqli($databaseHost, $databaseUser, $databasePassword, $databaseName, $databasePort);

    if ($connection->connect_error) {
        die('Connect Error (' . $connection->connect_errno . ') ' . $connection->connect_error);
    }

    return $connection;
}

/**
 * @param string $rootPath
 * @param string $magento2ConfigFile
 * @param string $configValue
 * @param string $defaultValue
 * @param bool   $checkDatabase
 *
 * @return array
 */
function getMagento2ConfigValue($rootPath, $magento2ConfigFile, $configValue, $defaultValue, $checkDatabase = true)
{
    $result = [];

    if ($checkDatabase) {
        $databaseConnection = getMagento2DatabaseConnection($rootPath);

        if ($databaseConnection) {
            $databaseConfigValue = trim($configValue);
            $databaseConfigValue = trim($databaseConfigValue, '/');
            $databaseConfigValue = preg_replace('/\*/', '%', $databaseConfigValue);

            while (substr_count($databaseConfigValue, '/') < 2) {
                $databaseConfigValue = sprintf('%s/%%', $databaseConfigValue);
            }

            $tablePrefix = getMagento2ConfigValue($rootPath, $magento2ConfigFile, 'db/table_prefix', '', false);

            if (count($tablePrefix) > 0) {
                $tablePrefix = reset($tablePrefix);
            }

            $configTableName = sprintf('%score_config_data', empty($tablePrefix) ? '' : $tablePrefix);

            /** @noinspection SqlResolve */
            $resultValues =
                $databaseConnection->query("SELECT `value` FROM `$configTableName` WHERE PATH like '$databaseConfigValue'");

            if ($resultValues) {
                $row = $resultValues->fetch_assoc();
                do {
                    if (is_array($row) && array_key_exists('value', $row)) {
                        $result[] = $row[ 'value' ];
                    }
                    $row = $resultValues->fetch_assoc();
                } while ($row);
                $resultValues->close();
            }
        }
    }

    $configData = eval(str_replace("<?php", "", file_get_contents($magento2ConfigFile)));

    foreach (preg_split('/\//', $configValue) as $configValuePart) {
        if (is_array($configData) && array_key_exists($configValuePart, $configData)) {
            $configData = $configData[ $configValuePart ];
        }
    }

    if ( ! empty($configData) && is_scalar($configData)) {
        $result[] = $configData;
    }

    return empty($result) ? [$defaultValue] : array_unique($result);
}

if ( ! isset($argv[ 1 ])) {
    echo "Please specify a Magento root path!\n";
    die(1);
}

if ( ! isset($argv[ 2 ])) {
    echo "Please specify a config value!\n";
    die(1);
}

$rootPath = rtrim($argv[ 1 ], '/');
$configValue = $argv[ 2 ];
$defaultValue = isset($argv[ 3 ]) ? $argv[ 3 ] : '';
$checkDatabase = isset($argv[ 4 ]) ? $argv[ 4 ] : 'true';

$magento1ConfigFile = sprintf('%s/app/etc/local.xml', $rootPath);
$magento2ConfigFile = sprintf('%s/app/etc/env.php', $rootPath);

if (file_exists($magento1ConfigFile)) {
    echo implode(' ',
        getMagento1ConfigValue($rootPath, $magento1ConfigFile, $configValue, $defaultValue, $checkDatabase === 'true'));
} else if (file_exists($magento2ConfigFile)) {
    echo implode(' ',
        getMagento2ConfigValue($rootPath, $magento2ConfigFile, $configValue, $defaultValue, $checkDatabase === 'true'));
} else {
    echo "No Magento configuration found!\n";
    die(1);
}
