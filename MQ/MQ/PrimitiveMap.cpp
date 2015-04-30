/**
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "PrimitiveMap.h"

#include <sstream>
#include <stdio.h>
//#include <string.h>

//using namespace activemq;
//using namespace activemq::util;
//using namespace decaf::lang::exceptions;
//using namespace decaf::util;
//using namespace std;

////////////////////////////////////////////////////////////////////////////////
PrimitiveMap::PrimitiveMap()/* : converter()*/
{
}

////////////////////////////////////////////////////////////////////////////////
PrimitiveMap::~PrimitiveMap()
{
}

//////////////////////////////////////////////////////////////////////////////////
//PrimitiveMap::PrimitiveMap( const decaf::util::Map<std::string, PrimitiveValueNode>& src )
//  : decaf::util::StlMap<std::string, PrimitiveValueNode>( src ), converter() {
//}

////////////////////////////////////////////////////////////////////////////////
PrimitiveMap::PrimitiveMap( const PrimitiveMap& src )
  //: decaf::util::StlMap<std::string, PrimitiveValueNode>( src ), converter()
{
}

//////////////////////////////////////////////////////////////////////////////////
//std::string PrimitiveMap::toString() const {
//
//    std::vector<std::string> keys = this->keySet();
//    ostringstream stream;
//
//    stream << "Begin Class PrimitiveMap:" << std::endl;
//
//    for( std::size_t i = 0; i < keys.size(); ++i ) {
//        stream << "map[" << keys[i] << "] = "
//               << this->get( keys[i] ).toString() << std::endl;
//    }
//
//    stream << "End Class PrimitiveMap:" << std::endl;
//
//    return stream.str();
//}

////////////////////////////////////////////////////////////////////////////////
bool PrimitiveMap::getBool( const std::string& key ) const
{

    PrimitiveValueNode node = this->get( key );
	return node.getBool();
   // return converter.convert<bool>( node );
}

////////////////////////////////////////////////////////////////////////////////
void PrimitiveMap::setBool( const std::string& key, bool value )
{

    PrimitiveValueNode node;
    node.setBool( value );

    this->put( key, node );
}

////////////////////////////////////////////////////////////////////////////////
unsigned char PrimitiveMap::getByte( const std::string& key ) const
{

    PrimitiveValueNode node = this->get( key );
	return node.getByte();
    //return converter.convert<unsigned char>( node );
}

////////////////////////////////////////////////////////////////////////////////
void PrimitiveMap::setByte( const std::string& key, unsigned char value )
{
    PrimitiveValueNode node;
    node.setByte( value );

    this->put( key, node );
}

////////////////////////////////////////////////////////////////////////////////
char PrimitiveMap::getChar( const std::string& key ) const
{
    PrimitiveValueNode node = this->get( key );
	return node.getChar();
    //return converter.convert<char>( node );
}

////////////////////////////////////////////////////////////////////////////////
void PrimitiveMap::setChar( const std::string& key, char value )
{
    PrimitiveValueNode node;
    node.setChar( value );

    this->put( key, node );
}

////////////////////////////////////////////////////////////////////////////////
short PrimitiveMap::getShort( const std::string& key ) const
{

    PrimitiveValueNode node = this->get( key );
	return node.getShort();
    //return converter.convert<short>( node );
}

////////////////////////////////////////////////////////////////////////////////
void PrimitiveMap::setShort( const std::string& key, short value )
{
    PrimitiveValueNode node;
    node.setShort( value );

    this->put( key, node );
}

////////////////////////////////////////////////////////////////////////////////
int PrimitiveMap::getInt( const std::string& key ) const
{

    PrimitiveValueNode node = this->get( key );
	return node.getInt();
    //return converter.convert<int>( node );
}

////////////////////////////////////////////////////////////////////////////////
void PrimitiveMap::setInt( const std::string& key, int value )
{
    PrimitiveValueNode node;
    node.setInt( value );

    this->put( key, node );
}

////////////////////////////////////////////////////////////////////////////////
long long PrimitiveMap::getLong( const std::string& key ) const
{

    PrimitiveValueNode node = this->get( key );
	return node.getLong();
    //return converter.convert<long long>( node );
}

////////////////////////////////////////////////////////////////////////////////
void PrimitiveMap::setLong( const std::string& key, long long value )
{
    PrimitiveValueNode node;
    node.setLong( value );

    this->put( key, node );
}

////////////////////////////////////////////////////////////////////////////////
double PrimitiveMap::getDouble( const std::string& key ) const
{

    PrimitiveValueNode node = this->get( key );
	return node.getDouble();
    //return converter.convert<double>( node );
}

////////////////////////////////////////////////////////////////////////////////
void PrimitiveMap::setDouble( const std::string& key, double value )
{
    PrimitiveValueNode node;
    node.setDouble( value );

    this->put( key, node );
}

////////////////////////////////////////////////////////////////////////////////
float PrimitiveMap::getFloat( const std::string& key ) const
{

    PrimitiveValueNode node = this->get( key );
	return node.getFloat();
    //return converter.convert<float>( node );
}

////////////////////////////////////////////////////////////////////////////////
void PrimitiveMap::setFloat( const std::string& key, float value )
{
    PrimitiveValueNode node;
    node.setFloat( value );

    this->put( key, node );
}

////////////////////////////////////////////////////////////////////////////////
std::string PrimitiveMap::getString( const std::string& key ) const
{

    PrimitiveValueNode node = this->get( key );
	return node.getString();
   // return converter.convert<std::string>( node );
}

////////////////////////////////////////////////////////////////////////////////
void PrimitiveMap::setString( const std::string& key, const std::string& value )
{
    PrimitiveValueNode node;
    node.setString( value );

    this->put( key, node );
}

//////////////////////////////////////////////////////////////////////////////////
//std::vector<unsigned char> PrimitiveMap::getByteArray( const std::string& key ) const {
//
//    PrimitiveValueNode node = this->get( key );
//    return converter.convert< std::vector<unsigned char> >( node );
//}
//
//////////////////////////////////////////////////////////////////////////////////
//void PrimitiveMap::setByteArray( const std::string& key, const std::vector<unsigned char>& value ) {
//
//    PrimitiveValueNode node;
//    node.setByteArray( value );
//
//    this->put( key, node );
//}

const PrimitiveValueNode& PrimitiveMap::get( const std::string& key ) const
{
	std::map<std::string,PrimitiveValueNode>::const_iterator iter;
	iter = valueMap.find( key );
	if( iter == valueMap.end() )
	{
		//throw NoSuchElementException(
		//    __FILE__, __LINE__, "Key does not exist in map" );
		PrimitiveValueNode node;
		return node;
	}

	return iter->second;
}

/**
* {@inheritDoc}
*/
void PrimitiveMap::put( const std::string& key, const PrimitiveValueNode& value )
{
	valueMap[key] = value;
}
