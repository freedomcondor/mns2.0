#include "vns_loop_functions.h"

#define RECORD 1
#define DISPLACE 1

namespace argos {

   /****************************************/
   /****************************************/

   CVNSLoopFunctions::CVNSLoopFunctions() {}

   /****************************************/
   /****************************************/

   void CVNSLoopFunctions::Init(TConfigurationNode& t_tree) {
      m_unStepCount = 0;
      m_pcRNG = CRandom::CreateRNG("argos");

      using TValueType = std::pair<const std::string, CAny>;
      /* create a vector of the drones */
      for(const TValueType& t_robot : GetSpace().GetEntitiesByType("drone")) {
         m_vecDrones.emplace_back(any_cast<CDroneEntity*>(t_robot.second));
      }
   }

   /****************************************/
   /****************************************/

   void CVNSLoopFunctions::Reset() {
      m_unStepCount = 0;

if (RECORD == 1) {
      for(SDrone& s_drone : m_vecDrones) {
         s_drone.OutputFileStream.close();
         s_drone.OutputFileStream.clear();
         s_drone.OutputFileStream.open(s_drone.Entity->GetId() + ".csv",
                                       std::ios_base::out | std::ios_base::trunc);
      }
}
   }

   /****************************************/
   /****************************************/

   void CVNSLoopFunctions::PostStep() {
      m_unStepCount++;

if (RECORD == 1) {
      UInt32 unTime = GetSpace().GetSimulationClock();
      /* write the positions of all robots to an output file */
      for(SDrone& s_drone : m_vecDrones) {
         const CVector3& cDronePosition =
            s_drone.Entity->GetEmbodiedEntity().GetOriginAnchor().Position;
         const CQuaternion& cDroneOrientation =
            s_drone.Entity->GetEmbodiedEntity().GetOriginAnchor().Orientation;
         std::string strOutputBuffer(s_drone.Entity->GetDebugEntity().GetBuffer("loop_functions"));
         strOutputBuffer.erase(std::remove(std::begin(strOutputBuffer),
                                           std::end(strOutputBuffer),
                                           '\n'),
                               std::end(strOutputBuffer));
         s_drone.OutputFileStream << unTime << ","
                                  << cDronePosition << ","
                                  << cDroneOrientation << ","
                                  << strOutputBuffer << std::endl;
      }
}

if (DISPLACE == 1) {
      UInt32 unRemoveStep = 200;
      UInt32 unAddinStep = 250;
      CRange<Real> rangeX = CRange<Real>(-7.2, 7.2);
      CRange<Real> rangeY = CRange<Real>(-1.2, 1.2);
      Real removePositionX = -8;
      Real removePositionY = -8;
      UInt32 unDroneNumber = 45;

      if (m_unStepCount == unRemoveStep) {
         int robot_index = 6;
         bool flag = false;
         while (flag == false) {
            robot_index = m_pcRNG->Uniform(CRange<UInt32>(1, unDroneNumber+1)); // 1 to 45
            robot_name.str(""); 
            robot_name << "drone" << robot_index;
            std::cout << "trying " << robot_name.str() << std::endl;
            for(SDrone& s_drone: m_vecDrones) {
               if (s_drone.Entity->GetId() == robot_name.str()) {
                  m_originPosition = s_drone.Entity->GetEmbodiedEntity().GetOriginAnchor().Position;
                  std::cout << "position" << m_originPosition << std::endl;
                  //if ((m_originPosition.GetY() > 0.5) || (m_originPosition.GetY() < -0.5)) { // leaf
                  //if ((m_originPosition.GetY() < 0.5) && (m_originPosition.GetY() > -0.5) &&
                  //    (robot_index != 6)) { // inner node
                  //if (robot_index != 6) { // not root
                  if (1) {
                     std::cout << "hit leaf" << std::endl;
                     MoveEntity(s_drone.Entity->GetEmbodiedEntity(), 
                                CVector3(removePositionX, removePositionY, m_originPosition.GetZ()), 
                                CQuaternion(1,0,0,0), 
                                false);
                     flag = true;
                     break;
                  }
               }
            }
         }

         std::cout << "displaceing " << robot_name.str() << std::endl;
      }

      if (m_unStepCount == unAddinStep) {
         std::cout << "adding in " << robot_name.str() << std::endl;

         DistanceFile.close();
         DistanceFile.clear();
         DistanceFile.open("distance.csv",
                           std::ios_base::out | std::ios_base::trunc);

         Real distance;
         for(SDrone& s_drone: m_vecDrones) {
            if (s_drone.Entity->GetId() == robot_name.str()) {
               bool flag = false;
               while (flag == false) {
                  Real x_number = m_pcRNG->Uniform(rangeX);
                  Real y_number = m_pcRNG->Uniform(rangeY);
                  Real z_number = s_drone.Entity->GetEmbodiedEntity().GetOriginAnchor().Position.GetZ();
                  distance = (m_originPosition - CVector3(x_number,y_number,z_number)).Length();
                  flag = MoveEntity(s_drone.Entity->GetEmbodiedEntity(), 
                                    CVector3(x_number,y_number,z_number), 
                                    CQuaternion(1,0,0,0), 
                                    false);
               }
               DistanceFile << distance << std::endl;
               break;
            }
         }
      }
}
   }

   /****************************************/
   /****************************************/

   CColor CVNSLoopFunctions::GetFloorColor(const CVector2& c_position) {
      return CColor::GRAY90;
   }

   /****************************************/
   /****************************************/

   REGISTER_LOOP_FUNCTIONS(CVNSLoopFunctions, "vns_loop_functions_data_22_vertebrate_displace");

}
