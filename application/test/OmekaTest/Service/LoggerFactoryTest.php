<?php
namespace OmekaTest\Service;

use Zend\Log\Logger;
use Omeka\Service\LoggerFactory;
use Omeka\Test\TestCase;

class LoggerFactoryTest extends TestCase
{
    protected $factory;

    protected $validConfig = [
        'logger' => [
            'log' => true,
            'path' => '/dev/stdout',
            'priority' => Logger::NOTICE,
        ],
    ];

    public function setUp()
    {
        $this->factory = new LoggerFactory;
    }

    public function testCreatesService()
    {
        $factory = $this->factory;
        $logger = $factory(
            $this->getMockServiceLocator($this->validConfig), 'Foo'
        );
        $this->assertInstanceOf('Zend\Log\Logger', $logger);
    }

    protected function getMockServiceLocator(array $config)
    {
        $serviceLocator = $this->getMock('Zend\ServiceManager\ServiceLocatorInterface');
        $serviceLocator->expects($this->once())
            ->method('get')
            ->with($this->equalTo('Config'))
            ->will($this->returnValue($config));
        return $serviceLocator;
    }
}
